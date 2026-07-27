{ ... }:
{
  den.aspects.git.nixos = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.git ];
  };

  den.aspects.git.homeManager =
    { pkgs, ... }:
    {
      home.packages = [ pkgs.difftastic pkgs.gh ];
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
