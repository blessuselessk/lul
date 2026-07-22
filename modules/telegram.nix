{ ... }:
{
  den.aspects.telegram.homeManager = { pkgs, ... }: {
    home.packages = [ pkgs.telegram-desktop ];
  };
}
