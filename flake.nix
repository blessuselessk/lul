# DO-NOT-EDIT. This file was auto-generated using github:vic/flake-file.
# Use `nix run .#write-flake` to regenerate it.
{

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);

  inputs = {
    claude-desktop-debian.url = "github:aaddrick/claude-desktop-debian";
    den.url = "github:denful/den";
    dms = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:AvengeMedia/DankMaterialShell";
    };
    flake-file.url = "github:vic/flake-file";
    flake-parts = {
      inputs.nixpkgs-lib.follows = "nixpkgs-lib";
      url = "github:hercules-ci/flake-parts";
    };
    home-manager = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-community/home-manager";
    };
    idevicerestore = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "path:/home/lessuseless/Projects/idevicerestore";
    };
    import-tree.url = "github:vic/import-tree";
    llm-agents-nix.url = "github:numtide/llm-agents.nix";
    musnix.url = "github:musnix/musnix/8548782f0d1d0928daa3fffde8a008f72219a3f3";
    niri-flake = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:sodiboo/niri-flake";
    };
    niri-use-rs = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:blessuselessk/niri-use-rs/3a9303f";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    nixpkgs.url = "https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.xz";
    nixpkgs-lib.follows = "nixpkgs";
    omniroute.url = "github:diegosouzapw/OmniRoute";
    quickshell = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:quickshell-mirror/quickshell";
    };
    voxtype = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:peteonrails/voxtype";
    };
  };

}
