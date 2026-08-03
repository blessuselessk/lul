{ ... }:
{
  den.aspects.dms-plugins-desktop = {
    homeManager =
      { pkgs, ... }:
      {
        # mpv/file-roller fill a real gap: nothing on this host had a
        # registered app for video/mp4, audio/mpeg, zip/tar/etc. at all
        # before (`gio mime video/mp4` said "No default applications").
        # Installing them alone is enough - each is the sole app claiming
        # its MimeType list, so xdg-mime/gio resolve them as the implicit
        # default the moment the package is linked, with no explicit
        # mimeapps.list entry needed (verified live: `xdg-mime query
        # default video/mp4` -> mpv.desktop, and neither type appears in
        # ~/.config/mimeapps.list at all). An earlier version of this
        # aspect also had a home.activation script writing explicit
        # `xdg-mime default` entries "if unset" - dropped after confirming
        # live it never actually ran: by the time the check executed,
        # implicit resolution had already made `xdg-mime query default`
        # non-empty, so the guard was always true and it never wrote
        # anything. Revisit only if a second competing app (e.g. a second
        # video player) is ever added and needs an explicit tiebreaker.
        home.packages = [
          pkgs.mpvpaper # mpvpaper: video wallpapers
          pkgs.ffmpeg # mpvpaper: video processing
          pkgs.mpv
          pkgs.file-roller
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

        # nautilus (installed in modules/niri.nix, kept as a real file
        # manager app) ships org.gnome.Nautilus.desktop with Name=Files -
        # in DMS's app launcher that's indistinguishable from "the" Files
        # app, so it's what actually opens when clicking a generic "Files"
        # entry, even though inode/directory's actual default (above) is
        # dmsfilemanager. Launching an app icon execs its own Exec= line
        # directly - it never consults mimeapps.list defaults, so pointing
        # the default at dmsfilemanager doesn't stop this entry from
        # showing up too. A same-filename override in
        # ~/.local/share/applications takes full precedence over the
        # system one (XDG desktop file lookup, first match wins - it
        # doesn't merge fields) - NoDisplay=true drops it from menus/
        # launchers while leaving `nautilus` itself and this entry's
        # MimeType still usable as an explicit "Open With" fallback.
        xdg.dataFile."applications/org.gnome.Nautilus.desktop".text = ''
          [Desktop Entry]
          Type=Application
          Name=Files
          Comment=Access and organize files
          Exec=nautilus --new-window %U
          Icon=org.gnome.Nautilus
          Terminal=false
          NoDisplay=true
          Categories=GNOME;GTK;Utility;Core;FileManager;
          MimeType=inode/directory;application/x-7z-compressed;application/x-7z-compressed-tar;application/x-bzip;application/x-bzip-compressed-tar;application/x-compress;application/x-compressed-tar;application/x-cpio;application/x-gzip;application/x-lha;application/x-lzip;application/x-lzip-compressed-tar;application/x-lzma;application/x-lzma-compressed-tar;application/x-tar;application/x-tarz;application/x-xar;application/x-xz;application/x-xz-compressed-tar;application/zip;application/gzip;application/bzip2;application/x-bzip2-compressed-tar;application/vnd.rar;application/zstd;application/x-zstd-compressed-tar
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
