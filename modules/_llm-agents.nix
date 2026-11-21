{ inputs, ... }:
{
  flake-file.inputs.llm-agents-nix = {
    url = "github:numtide/llm-agents.nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.llm-agents.nixos = { pkgs, ... }:
    let
      # `claude` (from llm-agents-nix below) is the pinned Nix build.
      # `claude-code` and `cc` run the newest @anthropic-ai/claude-code
      # published on npm instead. --prefer-online makes npx re-check the
      # registry for "latest" rather than reuse a cached copy.
      npmClaudeCode = name: pkgs.writeShellApplication {
        inherit name;
        runtimeInputs = [ pkgs.nodejs ];
        text = ''
          exec npx --yes --prefer-online @anthropic-ai/claude-code@latest "$@"
        '';
      };
    in
    {
      environment.systemPackages = [
        (npmClaudeCode "claude-code")
        (npmClaudeCode "cc")
      ] ++ (with inputs.llm-agents-nix.packages.${pkgs.stdenv.hostPlatform.system}; [
        claude-code
      ]);
    };
}
