{ ... }:
{
  # Obsidian itself. The PowerDesk plugin lives in its own aspect
  # (./powerdesk.nix) so it can be dropped independently of the app.
  den.aspects.obsidian.homeManager =
    { pkgs, lib, ... }:
    {
      # Obsidian's license is unfree. This is a *home-manager* nixpkgs.config,
      # separate from the system one web-browsers.nix sets - home-manager
      # here builds its own `pkgs` from its own nixpkgs.config rather than
      # inheriting the system's (confirmed live: adding "obsidian" to
      # web-browsers.nix's system-level allowUnfreePredicate had no effect
      # on this aspect at all). Each surface needs its own predicate.
      #
      # Tried routing this through den.batteries.unfree instead (den's own
      # built-in for exactly this) and it silently failed: that battery only
      # activates through den's aspect-inclusion graph walk (a host/user's
      # own `includes` list resolving down into it), and this repo's
      # homeManager aspects - obsidian included - are wired to users by
      # grabbing `.homeManager` directly in hornicorn.nix's
      # `provides.to-users.homeManager.imports`, bypassing that graph
      # entirely (same pattern as telegram.nix - see
      # .claude/rules/dendritic-libraries.md). Confirmed empirically:
      # `nix eval .#nixosConfigurations.hornicorn.config.home-manager.users.lessuseless.unfree.packages`
      # came back `[ ]` even with `den.aspects.obsidian.includes = [
      # (den.batteries.unfree [ "obsidian" ]) ]` set - the battery's
      # `includes` was never walked, so the predicate never received
      # "obsidian" and the build failed the same unfree check again.
      # Adopting den.batteries.unfree properly would mean restructuring how
      # homeManager aspects reach users on this host - bigger than this
      # aspect's scope. A raw predicate here is what actually works given
      # the current wiring.
      nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "obsidian" ];

      home.packages = [ pkgs.obsidian ];

      # Vault lives at ~/vault, deliberately outside this repo. PowerDesk
      # (./powerdesk.nix) writes account credentials into
      # ~/vault/.obsidian/plugins/powerdesk/data.json in plain text, and
      # this repo gets pushed to GitHub on every commit (root CLAUDE.md's
      # apply workflow) - a vault path under
      # ~/Projects/blessuselessk/lul would leak those credentials the
      # moment anything under it got committed. Don't move the vault
      # in-repo without changing how PowerDesk's credential storage works.
      home.activation.obsidianVault = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
        $DRY_RUN_CMD ${pkgs.coreutils}/bin/mkdir -p "$HOME/vault"
      '';
    };
}
