{ ... }:
let
  # All first-party plugins ship in a single AvengeMedia/dms-plugins mono-repo.
  # Each subdir is a separate plugin; src is pointed at the subdir.
  rev = "ec1685daf791c5c9d30fd0f3bd7aeafcb063dddd";
  hash = "sha256-NjhR54elmw+O6cFX2rC2xZXFJk45QzQjabyJXIcV+6A=";
in
{
  den.aspects.dms-plugins-first-party = {
    homeManager =
      { pkgs, ... }:
      let
        repo = pkgs.fetchFromGitHub {
          owner = "AvengeMedia";
          repo = "dms-plugins";
          inherit rev hash;
        };
      in
      {
        programs.dank-material-shell.plugins = {
          # Execute custom commands with dynamic output display.
          dankActions.src = "${repo}/DankActions";

          # Daemon: notify when battery hits critical/warning thresholds.
          dankBatteryAlerts.src = "${repo}/DankBatteryAlerts";

          # Ambient light sensor — automatic brightness and screen dimming
          # via clight. Requires the clight daemon to be running.
          dankClight.src = "${repo}/DankClight";

          # Daemon: run custom scripts on DMS events (wallpaper change,
          # theme update, battery level change, etc.).
          dankHooks.src = "${repo}/DankHooks";

          # Control KDE Connect / Valent-connected devices: battery,
          # file send, find phone, more. Works with the valent aspect.
          dankKDEConnect.src = "${repo}/DankKDEConnect";

          # Launcher plugin: browse compositor and app keybindings.
          # Trigger: backslash (\).
          dankLauncherKeys.src = "${repo}/DankLauncherKeys";

          # Daemon: inline preview + syntax highlighting for Notepad.
          # Requires DMS >= 1.4.0.
          dankNotepadModule.src = "${repo}/DankNotepadModule";
        };
      };
  };
}
