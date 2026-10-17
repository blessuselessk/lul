{ inputs, ... }:
{
  flake-file.inputs.grok-bot = {
    url = "github:jordangarrison/grok-bot-flake";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.grok-bot.homeManager = { pkgs, ... }: {
    # Repackaged .deb of xAI's Grok Bot desktop agent (unfree). The flake's
    # own `packages` output already allows unfree internally, so no
    # nixpkgs.config.allowUnfreePackages entry is needed here (unlike
    # modules/proton-drive.nix, which fetches its binary through this
    # repo's own pkgs instance instead).
    home.packages = [ inputs.grok-bot.packages.${pkgs.stdenv.hostPlatform.system}.default ];
  };
}
