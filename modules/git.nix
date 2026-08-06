{ ... }:
{
  den.aspects.git.nixos = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.git ];
  };

  den.aspects.git.homeManager =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.difftastic pkgs.gh ];

      # Two GitHub accounts, one machine. Convention: repos live under
      # ~/Projects/<github-username>/ and that folder name picks the
      # identity + SSH key automatically via includeIf below. `gh auth`
      # (see credential helper further down) only controls the *gh CLI's*
      # own API calls (gh pr create, etc) — it has no directory-aware
      # switching (see cli/cli docs/multiple-accounts.md), so per-repo git
      # push/pull auth is handled over SSH instead, keyed off which
      # ~/Projects/<username>/ tree the repo sits in.
      programs.ssh = {
        enable = true;
        settings = {
          "github.com-lessuselesss" = {
            HostName = "github.com";
            User = "git";
            IdentityFile = "~/.ssh/id_ed25519_lessuselesss";
            IdentitiesOnly = true;
          };
          "github.com-blessuselessk" = {
            HostName = "github.com";
            User = "git";
            IdentityFile = "~/.ssh/id_ed25519_blessuselessk";
            IdentitiesOnly = true;
          };
        };
      };

      programs.git = {
        enable = true;
        signing.format = "ssh";
        settings = {
          user.name = "Ashley Barr";
          user.email = "261668912+blessuselessk@users.noreply.github.com";
          init.defaultBranch = "main";
          pull.rebase = true;
          pager.difftool = true;
          diff.tool = "difftastic";
          difftool.prompt = false;
          difftool.difftastic.cmd = "${pkgs.difftastic}/bin/difft $LOCAL $REMOTE";
          github.user = "blessuselessk";
          core.editor = "vim";
          # Let git ask `gh` for GitHub credentials instead of relying on a
          # manually-configured credential store. Requires `gh auth login`
          # once per machine; after that, git push/pull/clone against
          # github.com just work — no separate token file to manage.
          credential."https://github.com".helper = [ "" "!gh auth git-credential" ];
          alias = {
            "dff" = "difftool";
            "fap" = "fetch --all -p";
            "rm-merged" =
              "for-each-ref --format '%(refname:short)' refs/heads | grep -v master | xargs git branch -D";
            "recents" =
              "for-each-ref --sort=committerdate refs/heads/ --format='%(HEAD) %(color:yellow)%(refname:short)%(color:reset) - %(color:red)%(objectname:short)%(color:reset) - %(contents:subject) - %(authorname) (%(color:green)%(committerdate:relative)%(color:reset))'";
          };
        };
        includes = [
          {
            # ~/Projects/lessuselesss/** -> lessuselesss identity + key
            condition = "gitdir:~/Projects/lessuselesss/";
            contents = {
              user = {
                name = "lessuseless";
                email = "179788364+lessuselesss@users.noreply.github.com";
              };
              # Rewrite github.com URLs (however the repo was cloned -
              # gh defaults to https) to the SSH host alias above, so the
              # right key gets presented without touching the remote by
              # hand.
              url."git@github.com-lessuselesss:".insteadOf = [
                "https://github.com/"
                "git@github.com:"
              ];
            };
          }
          {
            # ~/Projects/blessuselessk/** -> blessuselessk identity + key
            condition = "gitdir:~/Projects/blessuselessk/";
            contents = {
              user = {
                name = "Ashley Barr";
                email = "261668912+blessuselessk@users.noreply.github.com";
              };
              url."git@github.com-blessuselessk:".insteadOf = [
                "https://github.com/"
                "git@github.com:"
              ];
            };
          }
        ];
        ignores = [
          ".DS_Store"
          "*.swp"
          ".direnv"
          ".envrc"
          ".envrc.local"
          ".env"
          ".env.local"
          ".jj"
          "devshell.toml"
          ".tool-versions"
          "*.key"
          "target"
          "result"
          "out"
          "old"
          "*~"
          ".aider*"
          ".crush*"
          "CRUSH.md"
          "GEMINI.md"
          "CLAUDE.md"
          ".workspaces"
          ".agents"
          ".claude"
          "AGENT*"
        ];
        lfs.enable = true;
      };

      programs.delta.enable = true;
      programs.delta.options = {
        line-numbers = true;
        side-by-side = false;
      };
    };
}
