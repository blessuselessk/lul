{ den, ... }:
{
  # user aspect for vanya ("Hamster" in /etc/passwd's GECOS field) - an
  # existing account created imperatively (useradd), never previously
  # managed by Nix. Deliberately does NOT include den.batteries.primary-user
  # (wheel + networkmanager): vanya's current group membership is just
  # "users", no sudo/admin access, and this migration shouldn't grant more
  # privilege than they already had. `users.mutableUsers = true` (the
  # default) means their existing password is left untouched either way -
  # this aspect only brings them under declarative management for identity/
  # home-manager purposes, so they get the same niri + Dank Material Shell
  # desktop as lessuseless (forwarded automatically via the host aspect's
  # `provides.to-users.homeManager`, which reaches every user on the host).
  den.aspects.vanya = {
    includes = [ den.batteries.define-user ];

    user = { ... }: { description = "Hamster"; };
  };
}
