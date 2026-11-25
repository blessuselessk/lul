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
          # The bundled voice helper defaults to /usr/share/alsa on Linux.
          export ALSA_CONFIG_PATH="''${ALSA_CONFIG_PATH:-${pkgs.alsa-lib}/share/alsa/alsa.conf}"
          exec npx --yes --prefer-online @openai/codex@latest "$@"
        '';
      })
    ];
  };
}
