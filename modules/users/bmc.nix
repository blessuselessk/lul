{ den, ... }:
{
  # user aspect for bmc - an existing account created imperatively
  # (useradd), never previously managed by Nix. Its login shell was left at
  # useradd's default of /bin/bash, which doesn't exist on NixOS (/bin only
  # holds "sh"), so greetd's session for bmc exited immediately on every
  # login attempt. Bringing bmc under define-user fixes this: NixOS sets
  # the declarative isNormalUser default shell (resolves to
  # /run/current-system/sw/bin/bash), the same shell lessuseless/aldair/
  # vanya already get. Deliberately does NOT include
  # den.batteries.primary-user (wheel + networkmanager): bmc's current
  # group membership is just "users", no sudo/admin access, and this
  # migration shouldn't grant more privilege than the account already had.
  # `users.mutableUsers = true` (the default) leaves the existing password
  # untouched either way.
  den.aspects.bmc = {
    includes = [ den.batteries.define-user den.aspects.grok-bot ];
  };
}
