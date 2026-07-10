{ lib, den, ... }:
{
  den.default.nixos.system.stateVersion = "26.05";
  den.default.homeManager.home.stateVersion = "26.05";

  # enable hm by default
  den.schema.user.classes = lib.mkDefault [ "homeManager" ];

  # blanket allow, matching the ground-truth config (not a named allowlist,
  # so den.batteries.unfree doesn't fit here)
  den.default.nixos.nixpkgs.config.allowUnfree = true;
}
