{
  # System-wide `claude` that always runs the newest @anthropic-ai/claude-code
  # published on npm, instead of a Nix build pinned by flake.lock.
  # --prefer-online makes npx re-check the registry for "latest" on each
  # launch rather than reuse a cached copy.
  #
  # Replaces the parked modules/_llm-agents.nix (llm-agents.nix's pinned
  # `claude`, plus the old `claude-code` / `cc` npx wrappers).
  den.aspects.claude-code.nixos = { pkgs, ... }: {
    environment.systemPackages = [
      (pkgs.writeShellApplication {
        name = "claude";
        runtimeInputs = [ pkgs.nodejs ];
        text = ''
          exec npx --yes --prefer-online @anthropic-ai/claude-code@latest "$@"
        '';
      })
    ];
  };
}
