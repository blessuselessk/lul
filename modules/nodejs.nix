{ ... }:
{
  den.aspects.nodejs.nixos = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.nodejs ];
  };
}
