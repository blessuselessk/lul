{ inputs, ... }:
{
  den.aspects.claude-settings.homeManager =
    { pkgs, lib, ... }:
    let
      pog = inputs.pog.packages.${pkgs.stdenv.hostPlatform.system}.pog.pog;

      # Declared copies checked into this repo - the source of truth this
      # aspect keeps hornicorn's live ~/.claude/ files in sync with.
      settingsDeclared = ./claude-settings/settings.json;
      claudeMdDeclared = ./claude-settings/CLAUDE.md;
      settingsLive = "$HOME/.claude/settings.json";
      claudeMdLive = "$HOME/.claude/CLAUDE.md";

      # Claude Code writes to settings.json itself - /theme, voice mode,
      # effort level, and other in-app toggles all land here - so this
      # can't be a normal home-manager-managed symlink into the nix store;
      # that would make the file read-only and break those toggles
      # outright. It stays a plain, writable file instead, and this is the
      # one place that decides whether the live copy still matches what's
      # declared in the repo. Shared (via string interpolation, not a
      # package) between the switch-time gate below and the `claude-config`
      # CLI's --diff/--pull/--push, so there's one definition of "in sync".
      statusOf = ''
        claude_settings_status() {
          local declared="$1" live="$2"
          if [ ! -e "$live" ]; then
            echo bootstrap
          elif ${pkgs.diffutils}/bin/diff -q "$declared" "$live" >/dev/null 2>&1; then
            echo in-sync
          else
            echo drifted
          fi
        }
      '';
    in
    {
      home.packages = [
        (pog {
          name = "claude-config";
          description = "Diff/resync ~/.claude/settings.json + CLAUDE.md against modules/claude-settings/ in blessuselessk/lul";
          flags = [
            {
              name = "diff";
              bool = true;
              description = "Show what's different between the repo's declared copy and what's actually on disk";
            }
            {
              name = "pull";
              bool = true;
              description = "Print the live file(s) so the changes can be pasted back into modules/claude-settings/ and committed";
            }
            {
              name = "push";
              bool = true;
              description = "Overwrite the live file(s) with the repo's declared copy, discarding whatever changed on disk";
            }
          ];
          script = helpers: with helpers; ''
            ${statusOf}
            check() {
              local label="$1" declared="$2" live="$3"
              case "$(claude_settings_status "$declared" "$live")" in
                bootstrap) echo "$label: not present on disk yet" ;;
                in-sync)   echo "$label: in sync" ;;
                drifted)   echo "$label: DRIFTED - live copy no longer matches the repo" ;;
              esac
            }

            if ${flag "diff"}; then
              check "settings.json" "${settingsDeclared}" "${settingsLive}"
              ${pkgs.diffutils}/bin/diff -u "${settingsDeclared}" "${settingsLive}" || true
              echo
              check "CLAUDE.md" "${claudeMdDeclared}" "${claudeMdLive}"
              ${pkgs.diffutils}/bin/diff -u "${claudeMdDeclared}" "${claudeMdLive}" || true
              exit 0
            fi

            if ${flag "pull"}; then
              echo "=== .claude/settings.json (paste into modules/claude-settings/settings.json) ==="
              cat "${settingsLive}"
              echo
              echo "=== .claude/CLAUDE.md (paste into modules/claude-settings/CLAUDE.md) ==="
              cat "${claudeMdLive}"
              exit 0
            fi

            if ${flag "push"}; then
              ${pkgs.coreutils}/bin/install -D -m644 "${settingsDeclared}" "${settingsLive}"
              ${pkgs.coreutils}/bin/install -D -m644 "${claudeMdDeclared}" "${claudeMdLive}"
              echo "Overwrote both live files with the repo's declared copy."
              exit 0
            fi

            echo "No action given - see claude-config --help (diff/pull/push)."
            exit 1
          '';
        })
      ];

      # Runs before home-manager writes any other files (writeBoundary), so
      # a drifted settings file stops the switch before anything else
      # happens - not just this aspect's own state. Bootstraps a missing
      # file (fresh machine, or the file got deleted) but refuses to
      # silently overwrite one that's already there and different from the
      # repo: the whole point is that an in-app toggle (theme, voice mode,
      # effort level, ...) or a hand-edited CLAUDE.md should get *reviewed*
      # into the repo (`claude-config --pull`) or explicitly discarded
      # (`claude-config --push`), never clobbered by a routine rebuild.
      #
      # Caveat to verify on first real deploy: this is wired through den's
      # home-manager integration into hornicorn's NixOS system activation
      # (see modules/users/lessuseless.nix), which should make a nonzero
      # exit here fail `nixos-rebuild switch` itself - not yet confirmed on
      # this host.
      home.activation.claudeSettingsGate = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
        ${statusOf}
        drifted=0

        settings_status=$(claude_settings_status "${settingsDeclared}" "${settingsLive}")
        case "$settings_status" in
          bootstrap)
            echo "claude-settings: settings.json missing on disk, seeding from the repo"
            $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -D -m644 "${settingsDeclared}" "${settingsLive}"
            ;;
          drifted)
            echo "claude-settings: settings.json has changed on disk since the repo copy was last synced"
            drifted=1
            ;;
        esac

        claude_md_status=$(claude_settings_status "${claudeMdDeclared}" "${claudeMdLive}")
        case "$claude_md_status" in
          bootstrap)
            echo "claude-settings: CLAUDE.md missing on disk, seeding from the repo"
            $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -D -m644 "${claudeMdDeclared}" "${claudeMdLive}"
            ;;
          drifted)
            echo "claude-settings: CLAUDE.md has changed on disk since the repo copy was last synced"
            drifted=1
            ;;
        esac

        if [ "$drifted" -ne 0 ]; then
          echo ""
          echo "claude-settings: stopping - live ~/.claude files differ from modules/claude-settings/."
          echo "  Run 'claude-config --diff' to see what changed, then either"
          echo "  'claude-config --pull' (copy the change into the repo, commit it) or"
          echo "  'claude-config --push' (overwrite the live file with the repo's version)."
          exit 1
        fi
      '';
    };
}
