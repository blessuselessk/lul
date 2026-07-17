{ inputs, ... }:
{
  # pinned to the exact rev the live system was using, for a
  # behavior-preserving port
  flake-file.inputs.nix-handy.url =
    "github:lessuseless-odds/nix-handy/d3869ec8bc4f9b62357a46b0c9d076bea6f7673d";

  # Handy speech-to-text (nix-handy fork of cjpais/Handy). udev rule opening
  # /dev/uinput to the "input" group is provided by the module itself; user
  # still needs to be in that group (see modules/lessuseless.nix).
  # The uinput kernel module must also be loaded at boot — without it the
  # device node exists but the udev rule never fires (udev only processes
  # the device when the module registers it), so /dev/uinput stays
  # root:root 0600 and rdev::grab() cannot create its re-injection device.
  den.aspects.handy = {
    nixos =
      { pkgs, ... }:
      {
        imports = [ inputs.nix-handy.nixosModules.default ];

        programs.handy.enable = true;

        # required at eval time: nix-handy's Cargo.lock has a git dependency
        # (cjpais/hf-hub) fetched via builtins.fetchGit, which shells out to a
        # real `git` binary.
        environment.systemPackages = [ pkgs.git ];

        boot.kernelModules = [ "uinput" ];
      };

    # Autostart via a proper systemd user service calling the `handy` wrapper
    # (not .handy-wrapped directly). The wrapper sets ALSA_PLUGIN_DIR,
    # GTK/GStreamer env, and other wrapGAppsHook4 variables that
    # libayatana-appindicator needs to register a clean SNI tray icon.
    # Without this, starting .handy-wrapped directly (e.g. via XDG autostart)
    # causes ALSA PCM errors and a broken/artifact icon in the DMS bar.
    homeManager = { ... }: {
      imports = [ inputs.nix-handy.homeManagerModules.default ];
      services.handy.enable = true;

      # Suppress the XDG autostart entry that nix-handy's package installs
      # (it points at .handy-wrapped directly, bypassing the Nix wrapper's
      # env setup). Setting Hidden=true ensures GNOME/niri session managers
      # ignore it; the systemd user service above is the sole launch path.
      xdg.configFile."autostart/Handy.desktop" = {
        force = true;
        text = ''
          [Desktop Entry]
          Hidden=true
        '';
      };
    };
  };
}
