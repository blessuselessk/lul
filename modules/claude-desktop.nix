{ inputs, ... }:
{
  flake-file.inputs.claude-desktop-debian.url = "github:aaddrick/claude-desktop-debian";

  den.aspects.claude-desktop.homeManager = { pkgs, ... }: {
    home.packages = [
      inputs.claude-desktop-debian.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];
  };
}
