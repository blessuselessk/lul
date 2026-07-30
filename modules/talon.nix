{ inputs, ... }:
{
  flake-file.inputs.talon-nix = {
    url = "github:nix-community/talon-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  # talon aspect — Talon Voice, closed-source hands-free/voice-coding engine.
  # talon-nix (nix-community, unofficial — see repo README) wraps the
  # upstream Linux tarball in a buildFHSEnv and installs udev rules for
  # supported hardware (e.g. Tobii eye trackers) via `services.udev.packages`.
  # Unfree; already covered by the global `allowUnfree = true` in
  # defaults.nix, so no extra allowlist entry is needed here.
  #
  # Wayland/niri caveat: Talon's input-injection path is X11/XTest-based.
  # Its FHS env bundles wayland/wayland-protocols/wlroots/xwayland, but niri
  # isn't wlroots — expect XWayland-scoped or degraded behavior for anything
  # beyond plain dictation until this has actually been exercised under niri.
  den.aspects.talon.nixos = {
    imports = [ inputs.talon-nix.nixosModules.talon ];
    programs.talon.enable = true;
  };
}
