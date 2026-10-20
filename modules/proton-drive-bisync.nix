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

      # inotifywait can't push changes to Proton Drive's side (no webhook -
      # the 15-minute timer below is the only way to catch remote edits),
      # but it can react to local edits in ~/P almost instantly instead of
      # waiting out the timer interval. `-r` makes it recurse into
      # subdirectories, which a plain systemd.path unit can't do (path
      # units only watch a directory's own immediate contents).
      #
      # The `while read -t 5` drains any further events for 5s of quiet
      # before firing - without it, an editor doing several
      # create/write/rename steps on one save would queue up that many
      # separate bisync runs back to back instead of one.
      watchScript = pkgs.writeShellScript "proton-drive-bisync-watch" ''
        ${pkgs.inotify-tools}/bin/inotifywait -mr -e create,delete,close_write,move "${localDir}" |
        while read -r _; do
          while read -r -t 5 _; do :; done
          systemctl --user start proton-drive-bisync.service
        done
      '';
    in
    {
      home.packages = [
        pkgs.rclone
        pkgs.inotify-tools
      ];

      systemd.user.services.proton-drive-bisync = {
        Unit = {
          Description = "Bidirectional sync of ~/P with Proton Drive";
          # Silent failures defeat the point of an unattended sync - surface
          # them as a desktop notification instead of leaving it to whoever
          # happens to check the journal.
          OnFailure = [ "proton-drive-bisync-notify-failure.service" ];
        };
        Service = {
          Type = "oneshot";
          ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p ${localDir}";
          # --resilient/--recover: rclone's documented way to let an
          # unattended/scripted run survive interruptions without falling
          # back to requiring a manual --resync.
          # --create-empty-src-dirs: without it bisync only moves files and
          # silently ignores directory creation/deletion on either side -
          # confirmed live 2026-10-20, an empty folder added on either end
          # produced "No changes found" with nothing propagated.
          ExecStart = "${pkgs.rclone}/bin/rclone bisync ${localDir} ${remote} --resilient --recover --create-empty-src-dirs -v";
        };
      };

      systemd.user.services.proton-drive-bisync-notify-failure = {
        Unit.Description = "Desktop notification for a failed Proton Drive bisync";
        Service = {
          Type = "oneshot";
          ExecStart = "${pkgs.libnotify}/bin/notify-send --urgency=critical 'Proton Drive sync failed' 'systemctl --user status proton-drive-bisync.service for details'";
        };
      };

      systemd.user.services.proton-drive-bisync-watch = {
        Unit.Description = "Watch ~/P and trigger a bisync on local changes";
        Service = {
          Type = "simple";
          ExecStart = watchScript;
          Restart = "on-failure";
        };
        Install.WantedBy = [ "default.target" ];
      };

      systemd.user.timers.proton-drive-bisync = {
        Unit.Description = "Periodic Proton Drive bisync (catches remote-side changes)";
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
