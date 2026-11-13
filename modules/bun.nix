{ ... }:
{
  den.aspects.bun.nixos = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.bun ];
  };
}
