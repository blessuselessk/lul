{ inputs, ... }:
{
  flake-file.inputs.niri-flake = {
    url = "github:sodiboo/niri-flake";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  # niri aspect - wraps sodiboo/niri-flake, replaces Plasma6/SDDM
  den.aspects.niri = {
    nixos =
      { pkgs, config, ... }:
      {
        imports = [ inputs.niri-flake.nixosModules.niri ];

        programs.niri.enable = true;

        security.polkit.enable = true;
        services.gnome.gnome-keyring.enable = true;
        security.pam.services.swaylock = { };

        services.greetd = {
          enable = true;
          settings.default_session = {
            command = "${config.programs.niri.package}/bin/niri-session";
            user = "greeter";
          };
        };
        # let niri-session set up PATH rather than systemd stripping it
        systemd.user.services.niri.enableDefaultPath = false;

        environment.sessionVariables.NIXOS_OZONE_WL = "1";

        environment.systemPackages = [ pkgs.xwayland-satellite ];
      };

    homeManager =
      { pkgs, ... }:
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

        # standard niri-flake companion set - not something specified,
        # freely swap any of these
        programs.alacritty.enable = true; # terminal   - Super+T
        programs.fuzzel.enable = true; # launcher   - Super+D
        programs.waybar.enable = true; # bar
        services.mako.enable = true; # notifications

        home.packages = with pkgs; [
          swaylock # lock   - Super+Alt+L
          swayidle
          swaybg
        ];

        # Docs: https://github.com/sodiboo/niri-flake/blob/main/docs.md
      };
  };
}
