{ den, ... }:
{
  den.aspects.nix-direnv.homeManager =
    { ... }:
    {
      # programs.direnv's hook is injected into whatever shell home-manager
      # manages (programs.bash/zsh/fish). Nothing else in this repo enables
      # a home-manager-managed shell, so without this, direnv installs but
      # never actually hooks into bash - `cd` into a dir with .envrc does
      # nothing, confirmed via `type -t direnv` returning "file" not a
      # function. $SHELL on hornicorn is bash, so that's what gets enabled.
      programs.bash.enable = true;

      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
      };
    };
}
