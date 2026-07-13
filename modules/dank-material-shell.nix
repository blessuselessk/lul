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
          inputs.dms.nixosModules.greeter
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
        programs.dank-material-shell.greeter = {
          enable = true;
          compositor.name = "niri";
          quickshell.package = lib.mkForce inputs.quickshell.packages.${pkgs.stdenv.hostPlatform.system}.default;
        };
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

        # DMS injects its own niri keybinds (Mod+Space launcher, Mod+N
        # notifications, Mod+Comma settings, Mod+P notepad, Super+Alt+L
        # lock, media keys, Mod+V clipboard) via the niri-flake `binds`
        # option - the matching entries in niri.nix's manual `binds` block
        # were removed to avoid double-defining the same key combos.
        programs.dank-material-shell.niri.enableKeybinds = true;

        # `includes` (on by default) is DMS's *other* mechanism for
        # delivering niri config - it works by having niri `include` KDL
        # fragment files DMS itself regenerates at runtime (colors, cursor,
        # layout, outputs, windowrules, wpblur, alttab). Disabled: it
        # requires niri's `include` KDL directive (with `optional=true`),
        # which is a bleeding-edge feature not present in the stable niri
        # 25.08 we have pinned - confirmed via `niri validate` directly
        # against the rendered config.kdl ("unexpected node `include`"),
        # which was the actual cause of the real session's "failed to
        # parse the config file" error (a real niri/DMS version mismatch,
        # not a config mistake). This costs the dynamic color/cursor/
        # theming sync for now; the static keybinds from `enableKeybinds`
        # above are unaffected, since those go through the normal
        # `programs.niri.settings.binds` option, not this mechanism.
        programs.dank-material-shell.niri.includes.enable = false;
      };
  };
}
