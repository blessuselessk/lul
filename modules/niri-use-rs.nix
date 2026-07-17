{ inputs, ... }:
{
  flake-file.inputs.niri-use-rs = {
    url = "github:blessuselessk/niri-use-rs/3a9303f";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.niri-use-rs.nixos =
    { pkgs, ... }:
    {
      imports = [ inputs.niri-use-rs.nixosModules.default ];

      programs.niri-use = {
        enable = true;
        # Override the default unwrapped base to compile in the `atspi` feature.
        # The nixos module re-wraps this with the requested tools on PATH.
        package = inputs.niri-use-rs.packages.${pkgs.stdenv.hostPlatform.system}.niri-use-unwrapped.overrideAttrs (old: {
          buildFeatures = (old.buildFeatures or [ ]) ++ [ "atspi" ];
        });
      };

      # AT-SPI2 accessibility bus daemon — apps register their UI element trees
      # here. niri-use's AT-SPI support reads from this bus; without it, apps
      # show up empty even though the feature compiled in fine.
      services.gnome.at-spi2-core.enable = true;
    };
}
