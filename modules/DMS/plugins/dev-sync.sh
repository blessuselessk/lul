#!/usr/bin/env bash
# Copies locally-authored DMS plugins from the repo into the live plugins directory
# as writable directories, overriding the read-only Nix store copies.
#
# Use this when iterating on plugin source without doing a full rebuild each time.
# After changes are confirmed, commit to the repo and nixos-rebuild to make permanent.
#
# Usage: ./modules/DMS/plugins/dev-sync.sh [plugin-name ...]
#   No args: syncs all locally-authored plugins
#   With args: syncs only the named plugins (directory names under this folder)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LIVE_DIR="$HOME/.config/DankMaterialShell/plugins"

# Collect plugins to sync
if [[ $# -gt 0 ]]; then
    PLUGINS=("$@")
else
    PLUGINS=()
    for d in "$SCRIPT_DIR"/*/; do
        PLUGINS+=("$(basename "$d")")
    done
fi

for plugin in "${PLUGINS[@]}"; do
    src="$SCRIPT_DIR/$plugin"
    if [[ ! -d "$src" ]]; then
        echo "SKIP: $plugin (not found in $SCRIPT_DIR)"
        continue
    fi

    # DMS uses camelCase directory names; the nix attribute name matches
    dest="$LIVE_DIR/$plugin"

    rm -rf "$dest"
    cp -r "$src" "$dest"
    chmod -R u+w "$dest"
    # Re-apply executable bit on any .sh files
    find "$dest" -name "*.sh" -exec chmod +x {} \;

    echo "OK: $plugin → $dest"
done

echo ""
echo "Run 'dms restart' to reload."
