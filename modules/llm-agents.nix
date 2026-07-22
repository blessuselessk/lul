{ inputs, ... }:
{
  flake-file.inputs.llm-agents-nix.url = "github:numtide/llm-agents.nix";

  den.aspects.llm-agents.homeManager = { pkgs, ... }: {
    home.packages = with inputs.llm-agents-nix.packages.${pkgs.stdenv.hostPlatform.system}; [
      claude-code
    ];
  };
}
