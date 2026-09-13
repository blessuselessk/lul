{ ... }:
{
  den.aspects.inkscape.homeManager = { pkgs, ... }: {
    home.packages = [ pkgs.inkscape ];
  };
}
