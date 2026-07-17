{ inputs, ... }:
{
  flake-file.inputs.niri-flake = {
    url = "github:sodiboo/niri-flake";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  # niri aspect - wraps sodiboo/niri-flake, replaces Plasma6/SDDM
  den.aspects.niri = {
    nixos =
      { pkgs, ... }:
      {
        imports = [ inputs.niri-flake.nixosModules.niri ];

        programs.niri.enable = true;
        # Use the unstable niri build to get ext-background-effect-v1 (background
        # blur) and the `include optional=true` KDL directive (required for DMS's
        # dynamic theming fragments). The stable 25.08 package has neither.
        programs.niri.package = inputs.niri-flake.packages.${pkgs.stdenv.hostPlatform.system}.niri-unstable;

        security.polkit.enable = true;
        services.gnome.gnome-keyring.enable = true;

        # xdg-desktop-portal-gtk provides the FileChooser portal backend for
        # niri sessions. Without it, file upload dialogs in Firefox and other
        # apps produce no picker - the only installed backend
        # (xdg-desktop-portal-gnome) has UseIn=gnome and ignores
        # XDG_CURRENT_DESKTOP=niri entirely.
        xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
        xdg.portal.config.niri.default = [ "gtk" ];

        # greetd is configured by the dank-material-shell aspect's greeter
        # module instead of here - it needs to own `default_session` so its
        # login UI actually launches instead of a bare niri-session.
        environment.sessionVariables.NIXOS_OZONE_WL = "1";

        environment.systemPackages = [ pkgs.xwayland-satellite ];

        # Route home-manager's package installs through the NixOS system
        # profile (users.users.<name>.packages) instead of a runtime
        # `nix-env --set` call. Without this, home-manager's activation
        # script bails out of its "installPackages" step whenever that
        # ad-hoc nix-env profile build fails (observed here as `error:
        # opening file '.../user-environment.drv': No such file or
        # directory`, a store-write issue) - and because bash's `set -e`
        # aborts the rest of the script, the later "linkGeneration" step
        # (which actually deploys ~/.config/niri/config.kdl and every
        # other home-manager-managed dotfile) never runs. That's why
        # config.kdl stayed stuck on its very first generation no matter
        # what changed in `binds`. This option makes package installation
        # happen at system-build time instead, sidestepping the runtime
        # nix-env step entirely.
        home-manager.useUserPackages = true;
        home-manager.backupFileExtension = "hm-backup";
      };

    homeManager =
      { ... }:
      {
        # no `imports` needed here: the nixos class above already imports
        # niri-flake's nixosModules.niri, which wires
        # `home-manager.sharedModules = [ homeModules.config ]` for every
        # user on this host - importing it again here would double-declare
        # its options.

        # re-homed from the old services.xserver.xkb setting, since that's a
        # dead option now that xserver itself is gone - niri's config is
        # per-user (home-manager level), which is where this actually
        # takes effect under Wayland.
        programs.niri.settings.input.keyboard.xkb = {
          layout = "us";
          variant = "";
        };

        # niri-flake fully replaces niri's own built-in default config once
        # `programs.niri.settings`/`config` is touched at all - it does not
        # fall back to niri's stock keybinds, so an empty `binds` here means
        # no keybinds whatsoever. This is niri's actual upstream default
        # bind set (from the niri package's own
        # share/doc/niri/default-config.kdl), transcribed so the compositor
        # is usable out of the box.
        programs.niri.settings.binds = {
          "Mod+Shift+Slash".action.show-hotkey-overlay = { };

          "Mod+T".action.spawn = "alacritty";

          # Super+Alt+L (lock), the XF86Audio* media keys, Mod+Comma
          # (settings panel), and Mod+V (clipboard) collide with binds the
          # dank-material-shell aspect's
          # `programs.dank-material-shell.niri.enableKeybinds` already
          # defines (Mod+Space is DMS's launcher, on a different key than
          # our old Mod+D/fuzzel bind, which was dropped along with the
          # fuzzel package below since DMS's launcher replaces it).

          "Mod+O".repeat = false;
          "Mod+O".action.toggle-overview = { };
          "Mod+Q".repeat = false;
          "Mod+Q".action.close-window = { };

          "Mod+Left".action.focus-column-left = { };
          "Mod+Down".action.focus-window-down = { };
          "Mod+Up".action.focus-window-up = { };
          "Mod+Right".action.focus-column-right = { };
          "Mod+H".action.focus-column-left = { };
          "Mod+J".action.focus-window-down = { };
          "Mod+K".action.focus-window-up = { };
          "Mod+L".action.focus-column-right = { };

          "Mod+Ctrl+Left".action.move-column-left = { };
          "Mod+Ctrl+Down".action.move-window-down = { };
          "Mod+Ctrl+Up".action.move-window-up = { };
          "Mod+Ctrl+Right".action.move-column-right = { };
          "Mod+Ctrl+H".action.move-column-left = { };
          "Mod+Ctrl+J".action.move-window-down = { };
          "Mod+Ctrl+K".action.move-window-up = { };
          "Mod+Ctrl+L".action.move-column-right = { };

          "Mod+Home".action.focus-column-first = { };
          "Mod+End".action.focus-column-last = { };
          "Mod+Ctrl+Home".action.move-column-to-first = { };
          "Mod+Ctrl+End".action.move-column-to-last = { };

          "Mod+Shift+Left".action.focus-monitor-left = { };
          "Mod+Shift+Down".action.focus-monitor-down = { };
          "Mod+Shift+Up".action.focus-monitor-up = { };
          "Mod+Shift+Right".action.focus-monitor-right = { };
          "Mod+Shift+H".action.focus-monitor-left = { };
          "Mod+Shift+J".action.focus-monitor-down = { };
          "Mod+Shift+K".action.focus-monitor-up = { };
          "Mod+Shift+L".action.focus-monitor-right = { };

          "Mod+Shift+Ctrl+Left".action.move-column-to-monitor-left = { };
          "Mod+Shift+Ctrl+Down".action.move-column-to-monitor-down = { };
          "Mod+Shift+Ctrl+Up".action.move-column-to-monitor-up = { };
          "Mod+Shift+Ctrl+Right".action.move-column-to-monitor-right = { };
          "Mod+Shift+Ctrl+H".action.move-column-to-monitor-left = { };
          "Mod+Shift+Ctrl+J".action.move-column-to-monitor-down = { };
          "Mod+Shift+Ctrl+K".action.move-column-to-monitor-up = { };
          "Mod+Shift+Ctrl+L".action.move-column-to-monitor-right = { };

          "Mod+Page_Down".action.focus-workspace-down = { };
          "Mod+Page_Up".action.focus-workspace-up = { };
          "Mod+U".action.focus-workspace-down = { };
          "Mod+I".action.focus-workspace-up = { };
          "Mod+Ctrl+Page_Down".action.move-column-to-workspace-down = { };
          "Mod+Ctrl+Page_Up".action.move-column-to-workspace-up = { };
          "Mod+Ctrl+U".action.move-column-to-workspace-down = { };
          "Mod+Ctrl+I".action.move-column-to-workspace-up = { };

          "Mod+Shift+Page_Down".action.move-workspace-down = { };
          "Mod+Shift+Page_Up".action.move-workspace-up = { };
          "Mod+Shift+U".action.move-workspace-down = { };
          "Mod+Shift+I".action.move-workspace-up = { };

          "Mod+WheelScrollDown" = {
            cooldown-ms = 150;
            action.focus-workspace-down = { };
          };
          "Mod+WheelScrollUp" = {
            cooldown-ms = 150;
            action.focus-workspace-up = { };
          };
          "Mod+Ctrl+WheelScrollDown" = {
            cooldown-ms = 150;
            action.move-column-to-workspace-down = { };
          };
          "Mod+Ctrl+WheelScrollUp" = {
            cooldown-ms = 150;
            action.move-column-to-workspace-up = { };
          };

          "Mod+WheelScrollRight".action.focus-column-right = { };
          "Mod+WheelScrollLeft".action.focus-column-left = { };
          "Mod+Ctrl+WheelScrollRight".action.move-column-right = { };
          "Mod+Ctrl+WheelScrollLeft".action.move-column-left = { };

          "Mod+Shift+WheelScrollDown".action.focus-column-right = { };
          "Mod+Shift+WheelScrollUp".action.focus-column-left = { };
          "Mod+Ctrl+Shift+WheelScrollDown".action.move-column-right = { };
          "Mod+Ctrl+Shift+WheelScrollUp".action.move-column-left = { };

          "Mod+1".action.focus-workspace = 1;
          "Mod+2".action.focus-workspace = 2;
          "Mod+3".action.focus-workspace = 3;
          "Mod+4".action.focus-workspace = 4;
          "Mod+5".action.focus-workspace = 5;
          "Mod+6".action.focus-workspace = 6;
          "Mod+7".action.focus-workspace = 7;
          "Mod+8".action.focus-workspace = 8;
          "Mod+9".action.focus-workspace = 9;
          "Mod+Ctrl+1".action.move-column-to-workspace = 1;
          "Mod+Ctrl+2".action.move-column-to-workspace = 2;
          "Mod+Ctrl+3".action.move-column-to-workspace = 3;
          "Mod+Ctrl+4".action.move-column-to-workspace = 4;
          "Mod+Ctrl+5".action.move-column-to-workspace = 5;
          "Mod+Ctrl+6".action.move-column-to-workspace = 6;
          "Mod+Ctrl+7".action.move-column-to-workspace = 7;
          "Mod+Ctrl+8".action.move-column-to-workspace = 8;
          "Mod+Ctrl+9".action.move-column-to-workspace = 9;

          "Mod+BracketLeft".action.consume-or-expel-window-left = { };
          "Mod+BracketRight".action.consume-or-expel-window-right = { };
          "Mod+Period".action.expel-window-from-column = { };

          "Mod+R".action.switch-preset-column-width = { };
          "Mod+Shift+R".action.switch-preset-window-height = { };
          "Mod+Ctrl+R".action.reset-window-height = { };
          "Mod+F".action.maximize-column = { };
          "Mod+Shift+F".action.fullscreen-window = { };
          "Mod+Ctrl+F".action.expand-column-to-available-width = { };
          "Mod+C".action.center-column = { };
          "Mod+Ctrl+C".action.center-visible-columns = { };

          "Mod+Minus".action.set-column-width = "-10%";
          "Mod+Equal".action.set-column-width = "+10%";
          "Mod+Shift+Minus".action.set-window-height = "-10%";
          "Mod+Shift+Equal".action.set-window-height = "+10%";

          "Mod+Shift+V".action.switch-focus-between-floating-and-tiling = { };
          "Mod+Shift+Space".action.toggle-window-floating = { };
          "Mod+W".action.toggle-column-tabbed-display = { };

          "Print".action.screenshot = { };
          "Ctrl+Print".action.screenshot-screen = { };
          "Alt+Print".action.screenshot-window = { };

          "Mod+Escape".allow-inhibiting = false;
          "Mod+Escape".action.toggle-keyboard-shortcuts-inhibit = { };

          "Mod+Shift+E".action.quit = { };
          "Ctrl+Alt+Delete".action.quit = { };

          "Mod+Shift+P".action.power-off-monitors = { };
        };

        # standard niri-flake companion set - not something specified,
        # freely swap any of these
        programs.alacritty.enable = true; # terminal - Mod+T

        # waybar/fuzzel/mako/swaylock/swayidle/swaybg were all dropped:
        # dank-material-shell's own README states it "replaces waybar,
        # swaylock, swayidle, mako, fuzzel, polkit, and everything else
        # you'd normally stitch together" - confirmed by inspecting its
        # source, which has a full native QML lock screen implementation
        # (quickshell/Modules/Lock/) and no reference to shelling out to
        # swaylock/swayidle anywhere in the codebase.

        # Docs: https://github.com/sodiboo/niri-flake/blob/main/docs.md
      };
  };
}
