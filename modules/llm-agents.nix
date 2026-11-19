{ ... }:
{
  # Claude Code for every user. `claude`, `claude-code` and `cc` all run the
  # newest @anthropic-ai/claude-code published on npm. --prefer-online makes
  # npx re-check the registry for "latest" rather than reuse a cached copy.
  den.aspects.llm-agents.nixos = { pkgs, ... }:
    let
      npmClaudeCode = name: pkgs.writeShellApplication {
        inherit name;
        runtimeInputs = [ pkgs.nodejs ];
        text = ''
          exec npx --yes --prefer-online @anthropic-ai/claude-code@latest "$@"
        '';
      };
    in
    {
      environment.systemPackages = map npmClaudeCode [
        "claude"
        "claude-code"
        "cc"
      ];
    };
}
