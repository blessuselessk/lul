{ den, ... }:
{
  # user aspect
  den.aspects.lessuseless = {
    includes = [
      den.batteries.define-user
      den.batteries.primary-user
    ];

    # os-user battery (auto-activated) forwards this into
    # users.users.lessuseless, merging with what the batteries above set
    # (isNormalUser + home from define-user; wheel + networkmanager from
    # primary-user).
    user =
      { pkgs, ... }:
      {
        description = "lessuseless";
        extraGroups = [ "audio" "input" ];
        packages = [ pkgs.kdePackages.kate ];
      };
  };
}
