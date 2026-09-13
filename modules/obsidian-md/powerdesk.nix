{ ... }:
{
  # PowerDesk (community.obsidian.md/plugins/powerdesk, id "powerdesk"):
  # brings Microsoft 365 / Google / CalDAV calendars and mail into a vault.
  # Not in obsidianmd/obsidian-releases' community-plugins.json list at the
  # time this was written, so it can't be installed through Obsidian's
  # in-app "Browse community plugins" - fetched straight from its own
  # GitHub releases instead (github.com/obsidian-power-plugins/obsidian-power-desk).
  den.aspects.obsidian-powerdesk.homeManager =
    { pkgs, lib, ... }:
    let
      version = "2.12.2";
      baseUrl = "https://github.com/obsidian-power-plugins/obsidian-power-desk/releases/download/${version}";

      # Bump: change `version` above, then re-fetch each hash with
      # `nix-prefetch-url --type sha256 <url>` +
      # `nix hash to-sri --type sha256 <result>`. Obsidian's own in-app
      # "check for updates" can't do this for us — see the read-only note
      # below.
      mainJs = pkgs.fetchurl {
        url = "${baseUrl}/main.js";
        hash = "sha256-pk0V0HUnrBa4KlSQlhPh2ODeTjDX2elAfJvs478tWGo=";
      };
      manifestJson = pkgs.fetchurl {
        url = "${baseUrl}/manifest.json";
        hash = "sha256-31AJWJraIMFOW/nbo/k+Q4Ew2QSdmj+yu0lxUZbNRrc=";
      };
      stylesCss = pkgs.fetchurl {
        url = "${baseUrl}/styles.css";
        hash = "sha256-qdWVPFiECka2e5HuYRjo4tkn4JGXPbGIXZH40A2GeqQ=";
      };

      vaultRel = "vault";
      obsidianRel = "${vaultRel}/.obsidian";
      pluginRel = "${obsidianRel}/plugins/powerdesk";

      # Seed-only content for community-plugins.json - see the activation
      # script below for why this is copied in just once instead of kept in
      # sync like mainJs/manifestJson/stylesCss are.
      enabledPluginsSeed = pkgs.writeText "powerdesk-community-plugins.json" (builtins.toJSON [ "powerdesk" ]);
    in
    {
      # Plugin code only - these three are read-only symlinks into the Nix
      # store, kept in sync with `version` above on every switch. That's
      # deliberate: Obsidian's own "check for updates" can't write through a
      # symlink, so updates go through this file instead, same as every
      # other pinned version in this repo.
      home.file."${pluginRel}/main.js".source = mainJs;
      home.file."${pluginRel}/manifest.json".source = manifestJson;
      home.file."${pluginRel}/styles.css".source = stylesCss;

      # community-plugins.json and data.json are deliberately NOT managed
      # as home.file:
      #   - community-plugins.json is Obsidian's list of every enabled
      #     plugin in the vault, and it rewrites this file each time any
      #     plugin is toggled in Settings - a Nix-managed symlink here
      #     would either refuse that write (read-only store path) or get
      #     silently stomped back to just ["powerdesk"] on the next
      #     `nixos-rebuild switch`, undoing whatever else was toggled.
      #   - data.json is where PowerDesk stores account credentials once
      #     you connect Microsoft 365 / Google / CalDAV in Settings, in
      #     plain text. It must never become a Nix-managed file: this repo
      #     is pushed to GitHub on every commit, and letting `home.file`
      #     touch this path is how a live OAuth token would end up in a
      #     tracked module. Obsidian creates it itself the first time
      #     PowerDesk saves any setting - nothing to seed.
      #
      # This activation script only *seeds* community-plugins.json with
      # ["powerdesk"] the first time the vault has no such file yet -
      # e.g. a brand new vault at ~/vault. If the file already exists
      # (this vault has been opened before, or you've since toggled other
      # plugins), it's left alone; enable PowerDesk once by hand in
      # Settings > Community plugins in that case.
      home.activation.obsidianPowerdeskEnable = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        enabled_list="$HOME/${obsidianRel}/community-plugins.json"
        if [ ! -e "$enabled_list" ]; then
          echo "obsidian-powerdesk: community-plugins.json missing, seeding with [\"powerdesk\"]"
          $DRY_RUN_CMD ${pkgs.coreutils}/bin/install -D -m644 "${enabledPluginsSeed}" "$enabled_list"
        fi
      '';
    };
}
