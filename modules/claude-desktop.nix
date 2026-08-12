{ inputs, ... }:
{
  flake-file.inputs.claude-desktop-debian = {
    url = "github:aaddrick/claude-desktop-debian";
    inputs.nixpkgs.follows = "nixpkgs";
  };
  # pog: builds the `dispatch` CLI below (flag parsing/help/completion from a
  # plain Nix attrset instead of hand-rolled bash arg parsing - matches how
  # this repo already reaches for pkgs.writeShellApplication in modules/vm.nix
  # rather than a raw script, just with more CLI-shaped ergonomics).
  flake-file.inputs.pog = {
    url = "github:jpetrucciani/pog";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.claude-desktop.homeManager =
    { pkgs, ... }:
    let
      claude-desktop-pkg = inputs.claude-desktop-debian.packages.${pkgs.stdenv.hostPlatform.system}.default;
      pog = inputs.pog.packages.${pkgs.stdenv.hostPlatform.system}.pog.pog;

      # Everything below was, until now, a set of commands re-typed by hand
      # (and re-derived from scratch by an unrelated Claude Code session that
      # got the diagnosis wrong) each time the dispatch profile needed a
      # login, a status check, or a restart. One tool, one source of truth.
      dispatch-cli = pog {
        name = "dispatch";
        description = "Manage the headless Claude Desktop (Dispatch) background session";
        flags = [
          {
            name = "login";
            bool = true;
            description = "Run the (re-)authentication login visibly in this niri session; close the window when done";
          }
          {
            name = "status";
            short = "S";
            bool = true;
            description = "Show systemd --user status of the headless service";
          }
          {
            name = "start";
            short = "t";
            bool = true;
            description = "Start the headless service";
          }
          {
            name = "stop";
            short = "T";
            bool = true;
            description = "Stop the headless service";
          }
          {
            name = "restart";
            bool = true;
            description = "Restart the headless service";
          }
        ];
        script = helpers: with helpers; ''
          service="claude-desktop-headless.service"
          profile="$HOME/.config/Claude-dispatch"

          if ${flag "login"}; then
            debug "launching visible login session against $profile"
            echo "Log in, then close the window - the headless service reuses this same profile."
            WLR_RENDER_DRM_DEVICE=/dev/dri/renderD128 \
              ${pkgs.cage}/bin/cage -- ${claude-desktop-pkg}/bin/claude-desktop \
                --user-data-dir="$profile" --password-store=gnome-libsecret
            exit 0
          fi

          if ${flag "status"}; then exec systemctl --user status "$service"; fi
          if ${flag "start"}; then exec systemctl --user start "$service"; fi
          if ${flag "stop"}; then exec systemctl --user stop "$service"; fi
          if ${flag "restart"}; then exec systemctl --user restart "$service"; fi

          echo "No action given - see dispatch --help (login/status/start/stop/restart)."
          exit 1
        '';
      };
    in
    {
      home.packages = [
        claude-desktop-pkg
        pkgs.cage # kiosk compositor used to run claude-desktop headless below
        dispatch-cli
      ];

      # Runs Claude Desktop (and its Dispatch feature) in a headless Wayland
      # session that isn't tied to the physical seat at all, so it keeps
      # working whenever lessuseless isn't the one at the console - e.g.
      # aldair or vanya logged in on the real display via the DMS/greetd
      # greeter. `WLR_BACKENDS=headless` makes cage create a virtual
      # compositor (software framebuffer, no DRM/seat access), so it never
      # competes with whatever niri session is actually on screen and
      # doesn't show up to anyone using the laptop's real display. Claude
      # Code itself needs no display and already runs fine under this same
      # lingering user session (see `linger = true` in
      # modules/users/lessuseless.nix); this unit exists only because the
      # Desktop app/Dispatch is an Electron GUI that needs *some* compositor
      # to run at all.
      #
      # `--user-data-dir` is the actual fix for running this alongside a
      # normal interactively-launched claude-desktop: Electron's
      # single-instance lock is scoped to the profile directory, not the
      # whole app. Confirmed on this host (2026-07-27) that launching a
      # second `cage -- claude-desktop` while the default-profile instance
      # was already running hit that lock and got torn down mid-startup
      # ("failed to read Wayland events: Broken pipe" from cage, once the
      # second instance handed off to the first and quit). Giving this one
      # its own profile dir means it's a fully independent instance with
      # its own single-instance lock, its own login/session state, and no
      # collision with whatever you're running interactively day to day.
      #
      # Caveats to verify on first deploy, not yet tested on real hardware:
      # - This is a fresh profile, so it needs its own one-time interactive
      #   login - it does NOT inherit the default profile's session. Do
      #   that first, nested (visible) rather than headless, with the same
      #   --user-data-dir so the login carries over into the headless unit:
      #     cage -- ${claude-desktop-pkg}/bin/claude-desktop --user-data-dir=$HOME/.config/Claude-dispatch
      # - Cowork's VM sandbox uses a fixed-path socket under
      #   $XDG_RUNTIME_DIR (observed: claude-cowork-vm.sock), which doesn't
      #   appear to be namespaced per-profile. Running the default-profile
      #   instance and this one at the same time may collide there if both
      #   have Cowork/Dispatch active concurrently - watch for this
      #   specifically, haven't been able to confirm either way.
      # - xdg-desktop-portal isn't wired up for this headless display, so
      #   anything in Dispatch that shells out to a file picker or similar
      #   portal call may not resolve; fine for pure background/CLI-style
      #   dispatch work, worth watching for anything that needs a portal.
      systemd.user.services.claude-desktop-headless = {
        Unit = {
          Description = "Claude Desktop (Dispatch) in a headless cage session, own profile";
          After = [ "default.target" ];
        };
        Service = {
          # `WLR_RENDER_DRM_DEVICE`: without this, cage's headless backend
          # picks whichever DRM render node it enumerates first, which on
          # this host (PRIME offload: Intel iGPU + NVIDIA dGPU) was the
          # NVIDIA node (renderD129). That combination crashed cage's XWM
          # code on Electron's first paint ("cage: xwayland/xwm.c:592:
          # xwayland_surface_destroy: Assertion ... failed", "(EE) failed
          # to read Wayland events: Broken pipe") in testing on 2026-07-27.
          # Pinning it to the Intel node (renderD128 - confirmed via
          # `readlink /dev/dri/by-path/pci-0000:00:02.0-render`) matches
          # what the real niri session uses and was stable for 40+ seconds
          # under active use in that same test, vs. ~8 seconds to crash
          # without it. This line was missing from the first deploy of this
          # unit (it only existed in ad-hoc manual test commands, never
          # committed) - the deployed service ran on the NVIDIA node
          # unfixed for over an hour without crashing, so the crash isn't
          # guaranteed, but the fix is cheap and removes a known-bad
          # configuration.
          Environment = [
            "WLR_BACKENDS=headless"
            "WLR_LIBINPUT_NO_DEVICES=1"
            "WAYLAND_DISPLAY=wayland-dispatch"
            "WLR_RENDER_DRM_DEVICE=/dev/dri/renderD128"
          ];
          # `--password-store=gnome-libsecret`: Chromium picks its credential
          # backend by sniffing XDG_CURRENT_DESKTOP/DESKTOP_SESSION, which
          # cage doesn't set - without this it can't identify a keyring
          # backend at all (despite gnome-keyring being alive and its
          # `default` collection alias correctly present, confirmed via
          # `gdbus call ... org.freedesktop.Secret.Service.ReadAlias
          # "default"` on 2026-07-27) and silently falls back to storing
          # secrets in plaintext instead.
          ExecStart = "${pkgs.cage}/bin/cage -- ${claude-desktop-pkg}/bin/claude-desktop --user-data-dir=%h/.config/Claude-dispatch --password-store=gnome-libsecret";
          Restart = "on-failure";
          RestartSec = "10s";
        };
        # `default.target`, not `graphical-session.target` (contrast with
        # uxplay's service in modules/uxplay.nix) - this must start from
        # `linger` alone, with no graphical login required at all.
        Install.WantedBy = [ "default.target" ];
      };
    };
}
