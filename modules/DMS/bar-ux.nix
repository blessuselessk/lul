{ ... }:
{
  den.aspects.dms-plugins-bar-ux = {
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          pkgs.screenkey # screenkey: display keystrokes on screen
        ];

        programs.dank-material-shell.plugins = {
          # Widget: configurable bar button that opens a dropdown menu
          # of actions, plugin toggles, popouts, and IPC commands.
          dropdownMenu.src = pkgs.fetchFromGitHub {
            owner = "rdannenbring";
            repo = "dropdown-menu";
            rev = "00c49915c34de7f5a1829f93d2998195e164a529";
            hash = "sha256-9/tyygaxIVsy1ZELnNE0sIQLCyiRWCiKvN2cnNuaMJw=";
          };

          # Widget: hide and expand bar widgets with hover and click support.
          hiddenBar.src = pkgs.fetchFromGitHub {
            owner = "hthienloc";
            repo = "dms-hidden-bar";
            rev = "21b127f44bb5ee42621df94f509a0410ec803e55";
            hash = "sha256-gCmK9oIdz9lUCrUJqyDCkZgNG5XfmqUWqe8xRz7MgJw=";
          };

          # Widget: check and manage DNF and Flatpak package updates.
          # NOTE: DNF is Fedora-specific and will do nothing on NixOS;
          # included because it is present on the live system.
          pkgUpdate.src = pkgs.fetchFromGitHub {
            owner = "rahulmysore23";
            repo = "dms-pkg-update";
            rev = "a17dd21f6f72582ede70646db9d0eefc302d05bc";
            hash = "sha256-c0d0urqMo/2O1sDTj48beiv3qWHRpFnBctc1PzKz6pw=";
          };

          # Composite: display keystrokes on screen for tutorials / demos.
          # Requires DMS >= 1.5.0. Requires: screenkey.
          screenkey.src = pkgs.fetchFromGitHub {
            owner = "hthienloc";
            repo = "dms-screenkey";
            rev = "670cac883f9362707132bff4733de9034fee42b0";
            hash = "sha256-LRho8bSSQuUUm9a24JerkIeTOY85uqvg4WvdarFDEys=";
          };

          # Widget: one bar button that expands to reveal a group of
          # widgets inline, each with its own live pill and popout.
          widgetGroup.src = pkgs.fetchFromGitHub {
            owner = "rdannenbring";
            repo = "widget-group";
            rev = "cd748fb105375629bf32378c7d05d10e50c51281";
            hash = "sha256-+ApvThHcyP5Ivd+5nDrkZpKyoq9N1Aet+AJNKBPWfmY=";
          };
        };
      };
  };
}
