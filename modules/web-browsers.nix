{ inputs, ... }:
{
  flake-file.inputs.browser-previews = {
    url = "github:nix-community/browser-previews";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.web-browsers.nixos =
    { pkgs, lib, ... }:
    {
      programs.firefox.enable = true;

      nixpkgs.config.allowUnfreePredicate =
        pkg: builtins.elem (lib.getName pkg) [ "google-chrome" "google-chrome-dev" ];

      # --password-store=basic: originally set to gnome-libsecret here
      # (matching claude-desktop.nix's cage fix), but that traded a silent
      # hang for a different one. Root-caused via chrome://net-export +
      # direct D-Bus probing of org.freedesktop.secrets: the login gnome-
      # keyring collection is locked, and unlocking it requires a Prompt
      # dialog that niri can never render (niri doesn't implement the
      # xdg_foreign Wayland protocol - the exact same gap documented in
      # niri.nix's FileChooser comment, just hitting gnome-keyring-daemon's
      # own prompter instead of xdg-desktop-portal-gtk this time). With
      # gnome-libsecret selected, every cookie/credential touch blocks on
      # that unlock forever, so nearly every navigation times out
      # (ERR_TIMED_OUT) rather than completing. `basic` sidesteps the
      # keyring/D-Bus/prompt path entirely - weaker at-rest encryption for
      # saved passwords, but doesn't depend on a prompt niri can't show.
      # Revisit if the niri xdg_foreign gap ever gets fixed upstream, or if
      # the login keyring gets unlocked/reset out-of-band.
      environment.systemPackages = [
        (pkgs.google-chrome.override { commandLineArgs = "--password-store=basic"; })
        (inputs.browser-previews.packages.${pkgs.stdenv.hostPlatform.system}.google-chrome-dev.override {
          commandLineArgs = "--password-store=basic";
        })
      ];
    };

  # Per-profile launchers for the extra Google accounts migrated into the
  # main google-chrome profile directory by copying folders in directly
  # (2026-08-03) - that never generates the desktop entries Chrome's own
  # "Add"/"Create shortcut" flow would, so none of these profiles showed up
  # in the app launcher even though they're all fully usable via
  # --profile-directory. Default's own profile is already covered by the
  # system-wide google-chrome.desktop, so it's excluded here. Backslash-
  # escaping the space in "Profile N" (rather than quoting) matches the
  # Exec= format Chrome's own per-profile shortcuts use.
  den.aspects.web-browsers.homeManager =
    { lib, ... }:
    let
      profiles = [
        {
          slot = "profile-2";
          dir = "Profile 2";
          label = "ar4s.com (ashley.barr)";
        }
        {
          slot = "profile-3";
          dir = "Profile 3";
          label = "Ashley (gmail)";
        }
        {
          slot = "profile-4";
          dir = "Profile 4";
          label = "lessuseless (duck.com)";
        }
        {
          slot = "profile-5";
          dir = "Profile 5";
          label = "ar4sgpt";
        }
        {
          slot = "profile-6";
          dir = "Profile 6";
          label = "gordian (ar4s.com)";
        }
        {
          slot = "profile-8";
          dir = "Profile 8";
          label = "owner droid (gmail)";
        }
        {
          slot = "profile-9";
          dir = "Profile 9";
          label = "Ashley (icloud)";
        }
      ];
      escapedDir = dir: lib.replaceStrings [ " " ] [ "\\ " ] dir;
    in
    {
      xdg.desktopEntries = lib.listToAttrs (
        map (p: {
          name = "google-chrome-${p.slot}";
          value = {
            name = "Chrome — ${p.label}";
            genericName = "Web Browser";
            exec = "google-chrome-stable --profile-directory=${escapedDir p.dir} %U";
            icon = "google-chrome";
            terminal = false;
            type = "Application";
            categories = [
              "Network"
              "WebBrowser"
            ];
          };
        }) profiles
      );
    };
}
