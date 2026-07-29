# DO-NOT-EDIT. This file was auto-generated using github:vic/flake-file.
# Use `nix run .#write-flake` to regenerate it.
{
  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);

  nixConfig = {
    extra-substituters = [ "https://lul.cachix.org" ];
    extra-trusted-public-keys = [ "lul.cachix.org-1:du306UACvYmVfHgEtPd2XoPszPmgB9UyWk3iB+6ZYwE=" ];
  };

  inputs = {
    claude-desktop-debian.url = "github:aaddrick/claude-desktop-debian";
    den.url = "github:denful/den";
    dms = {
      url = "github:AvengeMedia/DankMaterialShell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-file.url = "github:vic/flake-file";
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    idevicerestore = {
      url = "github:blessuselessk/idevicerestore-nix/dbcb17fb8751e57f3ad0665ccac48439f3c0c2e5";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    import-tree.url = "github:vic/import-tree";
    llm-agents-nix.url = "github:numtide/llm-agents.nix";
    niri-flake = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    niri-use-rs = {
      url = "github:blessuselessk/niri-use-rs/3a9303f";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware";
    nixpkgs.url = "https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.xz";
    omniroute.url = "github:diegosouzapw/OmniRoute";
    pog.url = "github:jpetrucciani/pog";
    quickshell = {
      url = "github:quickshell-mirror/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    voxtype = {
      url = "github:peteonrails/voxtype";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
