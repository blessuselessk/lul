{ ... }:
{
  den.aspects.dms-plugins-desktop = {
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          pkgs.mpvpaper # mpvpaper: video wallpapers
          pkgs.ffmpeg # mpvpaper: video processing
        ];

        # dmsfilemanager is a DMS desktop plugin with no standalone .desktop
        # file, so DMS's Default Apps > File Manager picker can't see it
        # (it filters DesktopEntries by Categories=FileManager). This entry
        # registers it in the XDG database so it appears in the dropdown and
        # can be set as the inode/directory handler.
        xdg.dataFile."applications/dmsfilemanager.desktop".text = ''
          [Desktop Entry]
          Type=Application
          Name=DMS File Manager
          Comment=File Manager For DMS
          Icon=folder
          Exec=dms ipc call desktopWidget enable dmsfilemanager
          Terminal=false
          Categories=FileManager;
          MimeType=inode/directory;x-scheme-handler/file;
        '';

        programs.dank-material-shell.plugins = {
          # Desktop widget: circular audio visualizer with bars, wave,
          # rings, and bloom effects. Requires DMS >= 1.2.0.
          dankAudioVisualizer.src = pkgs.fetchFromGitHub {
            owner = "odtgit";
            repo = "DankAudioVisualizer";
            rev = "25424e8d570e000f4ab086c9e5e1122180861a65";
            hash = "sha256-bdWWaIZJW2wuaDaNor4QlYOzFEWGPc69xVsABuUloLg=";
          };

          # Desktop widget: display arbitrary command output on the desktop.
          desktopCommand.src = pkgs.fetchFromGitHub {
            owner = "yayuuu";
            repo = "desktopCommand";
            rev = "a2e663ee031918ea01e2e65cf88aa3ded85a53f8";
            hash = "sha256-RPmaeH2WMwnLURpdlAF0/CsER8KFlZNWUTHeGMDPKfo=";
          };

          # Desktop widget: file manager panel.
          # Requires DMS >= 1.2.0.
          # Patched: upstream uses Qt5Compat.GraphicalEffects (OpacityMask for
          # rounded corners) which isn't available in the Qt6 Quickshell env.
          # The patch drops the import and layer.effect block; corners are
          # square but the plugin loads. Track: suruibin/dms-filemanager#<issue>
          dmsfilemanager.src = pkgs.applyPatches {
            src = pkgs.fetchFromGitHub {
              owner = "suruibin";
              repo = "dms-filemanager";
              rev = "60ae65576334a2f3e0a4889e26ad2c925faefe4b";
              hash = "sha256-5Qi52nclQ6Gb0TmtsaRMlvDAdyjBZW/AAmnZ/H4Sfm0=";
            };
            patches = [ ./patches/dmsfilemanager-qt6-graphical-effects.patch ];
          };

          # Desktop widget: browse and open files in a selected directory.
          folderView.src = pkgs.fetchFromGitHub {
            owner = "hthienloc";
            repo = "dms-folder-view";
            rev = "dc528cabb164027097cd17751b3cfce71d3e77d4";
            hash = "sha256-h9Eka4CFTtBDU0NiEC3Vtm9AfnSwGIflz/Ytdo6pGPE=";
          };

          # Desktop widget: keybinding cheat sheet parsed live from the
          # compositor config. Requires DMS >= 1.2.0.
          keybindingCheatSheet.src = pkgs.fetchFromGitHub {
            owner = "stvnwrgs";
            repo = "dms-keybindings-cheat-sheet";
            rev = "65ce39ae417e3a08374d028b08fc18bdcb0ba046";
            hash = "sha256-kK2LSdzNne/M3iBn7p3h5ZytqVoZLVyOczpokzFa+ew=";
          };

          # Composite: play and switch video wallpapers with multi-monitor
          # support and a DankBar widget.
          # Requires: mpvpaper, ffmpeg. Requires DMS >= 1.5.0.
          mpvpaper.src = pkgs.fetchFromGitHub {
            owner = "tokisak1kurum1";
            repo = "mpvpaper-plugin";
            rev = "f0f83ad6fb034a02a9073bd7a2036cc879f78413";
            hash = "sha256-CffTJ0CXzj7Kr8i5HbJJGU4MkiURH9H7aUc5KROaQEY=";
          };
        };
      };
  };
}
