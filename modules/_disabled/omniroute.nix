{ inputs, ... }:
{
  flake-file.inputs.omniroute.url = "github:diegosouzapw/OmniRoute";

  # OmniRoute: self-hosted OpenAI-compatible AI gateway that aggregates 264
  # providers (90+ with free tiers) behind a single http://localhost:20128/v1
  # endpoint. Routing strategies, token compression, and auto-fallback tiers
  # are all handled server-side.
  #
  # Before activating on a host, create /etc/omniroute/secrets:
  #   JWT_SECRET=$(head -c 32 /dev/urandom | od -An -tx1 | tr -d ' \n')
  #   API_KEY_SECRET=$(head -c 32 /dev/urandom | od -An -tx1 | tr -d ' \n')
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

          npmDepsHash = "sha256-sEt336QPUDuOsKRlfKwoJ7KI7eHC+zu45PdmgLTf1I0=";

          inherit nodejs;

          nativeBuildInputs = with pkgs; [
            makeWrapper
            python3
            pkg-config
          ];

          buildInputs = with pkgs; [
            libsecret # keytar native module
          ];

          # Skip ALL install scripts during npm ci (prevents onnxruntime-node
          # from trying to download a prebuilt binary from GitHub, which fails
          # in the sandboxed build environment). C++ modules are rebuilt
          # explicitly in preBuild below.
          npmFlags = [ "--ignore-scripts" ];

          env = {
            NPM_CONFIG_LEGACY_PEER_DEPS = "true";
            NEXT_TELEMETRY_DISABLED = "1";
            OMNIROUTE_SKIP_POSTINSTALL = "1";
            PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD = "1";
          };

          preBuild = ''
            # Remove next/font/google — it fetches Inter from Google at
            # build time, which fails in the Nix sandbox. The font was only
            # used as a CSS variable alongside Tailwind's font-sans, so
            # removing it has no visible effect on the UI.
            sed -i '/import { Inter } from/d' src/app/layout.tsx
            sed -i '/const inter = Inter/,/^});$/d' src/app/layout.tsx
            sed -i 's/''${inter.variable} //g' src/app/layout.tsx

            # Compile C++ native modules that --ignore-scripts skipped.
            # onnxruntime-node is excluded: it downloads a prebuilt binary from
            # GitHub (no network in sandbox). Token compression is disabled in
            # the service env instead.
            npm rebuild better-sqlite3 keytar
          '';

          # Bypass the default npm-pack install: copy the entire built tree
          # (node_modules + .next output) so the MJS entry points can find
          # everything they need at runtime.
          installPhase = ''
            runHook preInstall
            mkdir -p $out/{bin,share/omniroute}

            # serve.mjs expects dist/server.js (or dist/server-ws.mjs).
            # The Next.js standalone build lands in .build/next/standalone/ —
            # move it into place before copying the tree to $out.
            mv .build/next/standalone dist

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
            # onnxruntime binary not available (requires GitHub download at
            # build time); disable compression pipeline to avoid startup errors
            COMPRESSION_PIPELINE_BREAKER_ENABLED = "false";
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
