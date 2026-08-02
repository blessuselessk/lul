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
}
