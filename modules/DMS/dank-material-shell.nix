{ inputs, ... }:
{
  flake-file.inputs = {
    dms = {
      url = "github:AvengeMedia/DankMaterialShell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # DMS's shell.qml uses a `//@ pragma AppId ...` directive that nixpkgs'
    # packaged quickshell (0.2.1) doesn't recognize ("ERROR: Unrecognized
    # pragma \"AppId com.danklinux.dms\"", found via direct quickshell log
    # inspection - this was the actual root cause of the greeter showing a
    # black screen/blinking cursor, unrelated to niri/DRM/VM at all -
    # confirmed unaffected by dms's own nixpkgs pin, since it resolves to
    # the same 0.2.1). quickshell's own flake tracks upstream (0.3.0+)
    # directly, so its package is used explicitly below instead of relying
    # on whatever nixpkgs revision either flake pins.
    quickshell = {
      url = "github:quickshell-mirror/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # Dank Material Shell aspect - QuickShell-based bar/launcher/notifications/
  # lock/greeter for niri, replacing the waybar+fuzzel+mako+swaylock companion
  # set and the bare greetd auto-session.
  den.aspects.dank-material-shell = {
    nixos =
      { pkgs, lib, ... }:
      {
        imports = [
          inputs.dms.nixosModules.dank-material-shell
          # nixosModules.greeter was removed from DMS upstream; the greeter
          # is now the nixpkgs-native `services.displayManager.dms-greeter`
          # module (no import needed).
        ];

        # Mirrors the home-manager side's `enable` - this NixOS-level one
        # is what auto-enables services.accounts-daemon and
        # services.power-profiles-daemon (DMS's own module gates those on
        # it); without it, DMS's UI shows them as "Not available" even
        # though the actual shell/bar works fine regardless.
        programs.dank-material-shell.enable = true;
        # This is a THIRD, separate quickshell.package option (distinct
        # from the greeter's and home-manager's own) that gets installed
        # system-wide via environment.systemPackages. Left at its default
        # (0.2.1), it regressed the AppId-pragma crash: the greeter's own
        # wrapper *appends* its bundled quickshell path to $PATH rather
        # than prepending, so the system-wide 0.2.1 (earlier in $PATH via
        # /run/current-system/sw/bin) won and shadowed the 0.3.0 override
        # below - black screen again, on the very next boot after enabling
        # this option. Overriding it here for consistency.
        programs.dank-material-shell.quickshell.package = lib.mkForce inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default;

        # Takes over `services.greetd` (via mkDefault) with an actual DMS
        # login UI instead of the bare niri-session auto-launch - the manual
        # greetd block that used to live in niri.nix has been removed so it
        # doesn't out-priority these defaults.
        # Moved from programs.dank-material-shell.greeter (removed upstream)
        # to the nixpkgs-native services.displayManager.dms-greeter.
        services.displayManager.dms-greeter = {
          enable = true;
          compositor.name = "niri";
          quickshell.package = lib.mkForce inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default;
        };

        # Root-cause fix for the "gnome-keyring login collection stays
        # locked" problem documented in web-browsers.nix and
        # claude-desktop.nix: on this greetd+DMS setup, the actual password
        # never reaches gnome-keyring, so its `login` collection is never
        # auto-unlocked at login - any app using --password-store=gnome-
        # libsecret (or Electron's default OSCrypt sniffing) then hits a
        # locked collection and needs an unlock Prompt dialog that hangs
        # instead of rendering. Originally attributed to niri lacking
        # xdg_foreign support - corrected in niri.nix's FileChooser comment
        # (2026-08-04): niri does advertise xdg_foreign v2, the real gap
        # was a long-running daemon that hadn't picked up a fix yet.
        #
        # `dms-greeter` (the quickshell greeter UI's own PAM service) is
        # NOT the right place for this - it only runs the greeter's local
        # credential check. `greetd` (this PAM service) is what the greetd
        # *daemon* itself uses for its own internal, single-handle
        # authenticate -> open-session PAM transaction when it actually
        # launches the user's session (confirmed live: it substacks/includes
        # `login` for auth/account/session - see nixpkgs'
        # services.greetd.nix). That single transaction is what carries the
        # real login password from pam_gnome_keyring's auth stage through to
        # its session stage, which is what's needed to auto-unlock the
        # keyring. Verified live on this host (2026-08-03) that both
        # `greetd` and `dms-greeter` had enableGnomeKeyring=false before
        # this change (`nix eval .#nixosConfigurations.hornicorn.config.
        # security.pam.services.<name>.enableGnomeKeyring`).
        security.pam.services.greetd.enableGnomeKeyring = true;
      };

    homeManager =
      { pkgs, lib, ... }:
      {
        imports = [
          inputs.dms.homeModules.dank-material-shell
          inputs.dms.homeModules.niri
        ];

        programs.dank-material-shell.enable = true;
        # `enable` alone doesn't start anything - the actual quickshell
        # process is a separate systemd user service gated by its own
        # toggle (defaults to false), which we hadn't set. Without this,
        # niri runs fine but no DMS bar/shell ever launches.
        programs.dank-material-shell.systemd.enable = true;
        programs.quickshell.package = lib.mkForce inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default;

        # DMS's keybinds (Mod+Space launcher, Mod+N notifications, Mod+Comma
        # settings, Mod+P notepad, Super+Alt+L lock, media/brightness keys,
        # Mod+V clipboard, Mod+X power menu) are added statically to the niri
        # config via enableKeybinds. The `includes` mechanism writes the other
        # runtime fragments (colors, cursor, layout, etc.) at runtime via
        # `include optional=true`. "binds" is excluded from filesToInclude
        # because dms/binds.kdl is only written via `dms keybinds set` (never
        # auto-populated from defaults), so leaving it in would leave an empty
        # file that shadows the static binds or causes future duplicate-bind
        # errors if someone runs `dms keybinds set` for the same key.
        programs.dank-material-shell.niri.enableKeybinds = true;
        programs.dank-material-shell.niri.includes.filesToInclude = [
          "alttab"
          "colors"
          "cursor"
          "layout"
          "outputs"
          "windowrules"
          "wpblur"
        ];
      };
  };
}
