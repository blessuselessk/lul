{ den, ... }:
{
  # age provides the `age` and `age-keygen` binaries gopass needs for its age
  # crypto backend. Initialise a new store with: gopass setup --crypto age
  den.aspects.gopass.homeManager = { pkgs, ... }: {
    home.packages = [ pkgs.age ];

    programs.gopass.enable = true;
  };
}
