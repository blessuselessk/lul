{
  # System-wide `codex` that always runs the newest @openai/codex published
  # on npm, instead of a Nix build pinned by flake.lock. Same approach as
  # modules/claude-code.nix: --prefer-online makes npx re-check the registry
  # for "latest" on each launch rather than reuse a cached copy.
  den.aspects.codex.nixos = { pkgs, ... }: {
    environment.systemPackages = [
      (pkgs.writeShellApplication {
        name = "codex";
        runtimeInputs = [ pkgs.nodejs ];
        text = ''
          exec npx --yes --prefer-online @openai/codex@latest "$@"
        '';
      })
    ];
  };
}
