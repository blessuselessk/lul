{ inputs, ... }:
{
  flake-file.inputs.omniroute.url = "github:diegosouzapw/OmniRoute";

  # OmniRoute: self-hosted OpenAI-compatible AI gateway that aggregates 264
  # providers (90+ with free tiers) behind a single http://localhost:20128/v1
  # endpoint. Routing strategies, token compression, and auto-fallback tiers
  # are all handled server-side.
  #
  # Before activating on a host, create /etc/omniroute/secrets:
  #   JWT_SECRET=$(openssl rand -hex 32)
  #   API_KEY_SECRET=$(openssl rand -hex 32)
  #   INITIAL_PASSWORD=<your-chosen-password>
  # chmod 400 /etc/omniroute/secrets; chown root:omniroute /etc/omniroute/secrets
  #
  # First rebuild will fail with a hash mismatch for npmDepsHash — copy the
  # "got:" hash from the error and replace lib.fakeHash below.
  den.aspects.omniroute = {
    nixos =
      { pkgs, lib, ... }:
      let
        nodejs = pkgs.nodejs_24;

        omniroute-pkg = pkgs.buildNpmPackage {
          pname = "omniroute";
          version = "3.8.49";
          src = inputs.omniroute;

          # Replace with the hash from the first failed build:
          #   nix build .#nixosConfigurations.hornicorn.config.system.build.toplevel
          #   (look for "got:" in the fetchNpmDeps error)
          npmDepsHash = lib.fakeHash;

          inherit nodejs;

          nativeBuildInputs = with pkgs; [
            makeWrapper
            python3
            pkg-config
          ];

          env = {
            NPM_CONFIG_LEGACY_PEER_DEPS = "true";
            NEXT_TELEMETRY_DISABLED = "1";
            # Skip Playwright browser downloads and postinstall hooks
            OMNIROUTE_SKIP_POSTINSTALL = "1";
            PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = "1";
          };

          preBuild = ''
            # Rebuild better-sqlite3 native module for this platform
            npm rebuild better-sqlite3
          '';

          # Bypass the default npm-pack install: copy the entire built tree
          # (node_modules + .next output) so the MJS entry points can find
          # everything they need at runtime.
          installPhase = ''
            runHook preInstall
            mkdir -p $out/{bin,share/omniroute}

            # -a preserves symlinks (npm workspace links, .bin/ shims, etc.)
            cp -a . $out/share/omniroute/

            makeWrapper ${nodejs}/bin/node $out/bin/omniroute \
              --chdir "$out/share/omniroute" \
              --add-flags "$out/share/omniroute/bin/omniroute.mjs"

            makeWrapper ${nodejs}/bin/node $out/bin/omniroute-reset-password \
              --chdir "$out/share/omniroute" \
              --add-flags "$out/share/omniroute/bin/reset-password.mjs"

            runHook postInstall
          '';
        };
      in
      {
        users.users.omniroute = {
          isSystemUser = true;
          group = "omniroute";
          description = "OmniRoute AI gateway";
        };
        users.groups.omniroute = { };

        systemd.services.omniroute = {
          description = "OmniRoute AI routing gateway";
          wantedBy = [ "multi-user.target" ];
          after = [ "network-online.target" ];
          wants = [ "network-online.target" ];

          # Service does not start until secrets file exists
          unitConfig.ConditionPathExists = "/etc/omniroute/secrets";

          environment = {
            PORT = "20128";
            DATA_DIR = "/var/lib/omniroute";
            NODE_ENV = "production";
            NEXT_TELEMETRY_DISABLED = "1";
            # No Playwright/browser in a headless service
            WEB_COOKIE_USE_BROWSER = "0";
            OMNIROUTE_BROWSER_POOL = "off";
            OMNIROUTE_MEMORY_MB = "1024";
          };

          serviceConfig = {
            Type = "simple";
            User = "omniroute";
            Group = "omniroute";
            ExecStart = "${omniroute-pkg}/bin/omniroute";
            StateDirectory = "omniroute";
            # Sensitive env vars (JWT_SECRET, API_KEY_SECRET, INITIAL_PASSWORD)
            EnvironmentFile = "/etc/omniroute/secrets";
            Restart = "on-failure";
            RestartSec = "5s";
            # Security hardening
            NoNewPrivileges = true;
            PrivateTmp = true;
            ProtectSystem = "strict";
            ProtectHome = true;
            ReadWritePaths = [ "/var/lib/omniroute" ];
          };
        };
      };
  };
}
