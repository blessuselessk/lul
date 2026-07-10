{ inputs, ... }:
{
  # pinned to the exact rev the live system was using, for a
  # behavior-preserving port
  flake-file.inputs.nix-handy.url =
    "github:lessuseless-odds/nix-handy/d3869ec8bc4f9b62357a46b0c9d076bea6f7673d";

  # Handy speech-to-text (nix-handy fork of cjpais/Handy). udev rule opening
  # /dev/uinput to the "input" group is provided by the module itself; user
  # still needs to be in that group (see modules/lessuseless.nix).
  den.aspects.handy.nixos =
    { pkgs, ... }:
    {
      imports = [ inputs.nix-handy.nixosModules.default ];

      programs.handy.enable = true;

      # required at eval time: nix-handy's Cargo.lock has a git dependency
      # (cjpais/hf-hub) fetched via builtins.fetchGit, which shells out to a
      # real `git` binary.
      environment.systemPackages = [ pkgs.git ];
    };
}
