{ inputs, ... }:
{
  # `pog` is already declared as a flake input by modules/claude-desktop.nix
  # (import-tree pulls that module in regardless of this one), so this
  # aspect doesn't redeclare flake-file.inputs.pog - matches how
  # claude-settings.nix and hosts/hornicorn.nix both just reuse it too.
  den.aspects.note.homeManager =
    { pkgs, ... }:
    let
      pog = inputs.pog.legacyPackages.${pkgs.stdenv.hostPlatform.system}.pog.pog;
    in
    {
      home.packages = [
        (pog {
          name = "note";
          description = "Append a timestamped line to notes.md - pass '> other.md' at the end to target a different file instead";
          strict = true;
          # No `flags`/`arguments` declared on purpose: the whole point is
          # to take whatever free-form words were typed and treat them as
          # one string, same as the original `note() { ... "$*" ... }`
          # shell function this replaces. Confirmed this is the intended
          # way to read raw argv in a flagless pog script against
          # jpetrucciani/nix's own mods/pog/general.nix (e.g. `fif`, which
          # checks "$#" and reads "$1" with no `flags`/`arguments` either).
          script = ''
            file="notes.md"
            text="$*"

            # Extract optional "> filename.md" off the end of the raw
            # input, same regex as the original function. Because `note`
            # is now a real executable rather than a sourced shell
            # function, the caller's own shell still parses an *unescaped*
            # `>` as real output redirection before `note` ever sees it -
            # exactly the same gotcha the original function had. Quote or
            # escape it: `note "quick idea > work.md"` or
            # `note quick idea \> work.md`.
            if [[ "$*" =~ ^(.*)[[:space:]]+\>[[:space:]]*([^[:space:]]+\.md)[[:space:]]*$ ]]; then
              text="''${BASH_REMATCH[1]}"
              file="''${BASH_REMATCH[2]}"
            fi

            # Strip one pair of surrounding double quotes, if present -
            # same naive strip as the original (not general shell-quote
            # parsing, just this one case).
            text="''${text#\"}"
            text="''${text%\"}"

            printf '[%s] %s\n' "$(date '+%Y-%m-%d@%H:%M:%S')" "$text" >> "$file"
          '';
        })
      ];
    };
}
