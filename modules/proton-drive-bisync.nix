{ ... }:
{
  # Bidirectional sync of ~/P with Proton Drive, via rclone's `bisync`
  # command against rclone's own "protondrive" backend. This is unrelated
  # to the official Proton Drive CLI in modules/proton-drive.nix - that
  # binary has no bisync/two-way-sync subcommand.
  #
  # rclone bisync itself has no daemon/background mode; rclone's own docs
  # drive periodic runs from the OS scheduler (they show a crontab
  # example), so a systemd user timer does that job here.
  #
  # Manual one-time setup (interactive, can't be declared in Nix):
  #   1. `rclone config create protondrive protondrive` and follow the
  #      prompts (email, password, 2FA) to create the `protondrive:` remote.
  #   2. `rclone bisync ~/P protondrive: --resync` once, to establish the
  #      baseline listing - bisync refuses to run without it.
  # The timer below never passes --resync itself: on a periodic job that
  # would silently re-flatten the baseline (preferring the local side) on
  # every scheduled run instead of reconciling both sides.
  den.aspects.proton-drive-bisync.homeManager =
    { config, pkgs, ... }:
    let
      localDir = "${config.home.homeDirectory}/P";
      remote = "protondrive:";
    in
    {
      home.packages = [ pkgs.rclone ];

      systemd.user.services.proton-drive-bisync = {
        Unit.Description = "Bidirectional sync of ~/P with Proton Drive";
        Service = {
          Type = "oneshot";
          ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${localDir}";
          # --resilient/--recover: rclone's documented way to let an
          # unattended/scripted run survive interruptions without falling
          # back to requiring a manual --resync.
          ExecStart = "${pkgs.rclone}/bin/rclone bisync ${localDir} ${remote} --resilient --recover -v";
        };
      };

      systemd.user.timers.proton-drive-bisync = {
        Unit.Description = "Periodic Proton Drive bisync";
        Timer = {
          OnBootSec = "5m";
          OnUnitActiveSec = "15m";
          # Laptop sleeps a lot; fire on resume if a tick was missed
          # instead of waiting out the rest of the interval.
          Persistent = true;
        };
        Install.WantedBy = [ "timers.target" ];
      };
    };
}
