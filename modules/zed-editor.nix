{ ... }:
{
  den.aspects.zed-editor.homeManager = { pkgs, ... }: {
    home.packages = [ pkgs.zed-editor ];
  };
}
