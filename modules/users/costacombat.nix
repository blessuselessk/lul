{ den, ... }:
{
  # user aspect for costacombat - the account formerly named bmc. It was
  # renamed by hand (usermod -l), keeping UID 1001 and its files; the home
  # folder moved to /home/costacombat. Declared here so NixOS keeps managing
  # it under the new name.
  #
  # Group "costacombat" holds only costacombat and lessuseless (see
  # modules/users/lessuseless.nix). It owns the shared folder at
  # /srv/costacombat. No sudo/wheel access is granted.
  den.aspects.costacombat = {
    includes = [ den.batteries.define-user den.aspects.grok-bot den.aspects.claude-desktop ];

    nixos.users.groups.costacombat = { };

    user = {
      uid = 1001;
      description = "costacombat";
      extraGroups = [ "costacombat" ];
    };
  };
}
