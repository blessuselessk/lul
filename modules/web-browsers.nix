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

      # --password-store=gnome-libsecret: Chrome's OSCrypt backend picks a
      # credential/cookie-encryption store by sniffing
      # XDG_CURRENT_DESKTOP/DESKTOP_SESSION. niri sets neither, so
      # auto-detection resolves to a keyring backend that never completes its
      # D-Bus handshake - every navigation needs the OSCrypt key to touch the
      # cookie store, so every page load hangs forever with no error (looks
      # exactly like "no internet"). Confirmed by: Incognito (ephemeral
      # cookie jar) worked in the same hung browser process; --password-store
      # =basic fixed it outright. Force the backend explicitly instead of
      # relying on auto-detection - same fix already applied to Claude
      # Desktop's bundled Chromium in claude-desktop.nix for the same reason.
      environment.systemPackages = [
        (pkgs.google-chrome.override { commandLineArgs = "--password-store=gnome-libsecret"; })
        (inputs.browser-previews.packages.${pkgs.stdenv.hostPlatform.system}.google-chrome-dev.override {
          commandLineArgs = "--password-store=gnome-libsecret";
        })
      ];
    };
}
