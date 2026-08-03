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
        # TEMPORARY: debug logging patches to root-cause "clicking a
        # recent file does nothing" (the recentFiles launcher plugin -
        # see productivity.nix's own temporary patch on that plugin).
        # Confirmed live the plugin's own executeItem() is never even
        # reached on a real click (zero log output, despite the plugin
        # loading fine and the underlying Qt.openUrlExternally mechanism
        # being proven to work in isolation) - these patches instrument
        # DMS core's own click-dispatch path (Controller.qml's
        # executeItem, AppSearchService's executePluginItem) one layer up,
        # to see which branch a real click actually takes and why it
        # never reaches the plugin. Revert once root-caused.
        #
        # `patches` doesn't reach these files at all: dms-shell's own
        # flake.nix scopes `src` (what `patches` applies to) to just
        # `./core` (the Go backend) for the unpackPhase. The QML tree
        # under $out/share/quickshell/dms is `cp -r`'d straight from the
        # flake's own untouched root source string-interpolated directly
        # into postInstall, completely bypassing src/patches (confirmed
        # live: applying via `patches` failed with "can't find file to
        # patch", since quickshell/ genuinely doesn't exist in the
        # ./core-scoped unpack root at all). Patching the already-`cp -r`'d
        # output files in an appended postInstall step is the only point
        # that actually reaches them.
        programs.dank-material-shell.package =
          inputs.dms.packages.${pkgs.stdenv.hostPlatform.system}.dms-shell.overrideAttrs
            (old: {
              postInstall = (old.postInstall or "") + ''
                chmod -R u+w $out/share/quickshell/dms/Modals/DankLauncherV2 $out/share/quickshell/dms/Services
                patch -p1 -d $out/share/quickshell/dms < ${./patches/controller-debug-logging.patch}
                patch -p1 -d $out/share/quickshell/dms < ${./patches/appsearchservice-debug-logging.patch}
              '';
            });
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
