{ inputs, ... }:
{
  # Not a flake - it's a plain skill repo (skills/typst/SKILL.md plus
  # supporting scripts/data), so this is fetched as source only and
  # pinned via flake.lock like any other non-flake input.
  flake-file.inputs.claude-skill-typst = {
    url = "github:lessuseless-automations/claude-skill-typst";
    flake = false;
  };

  # Claude Desktop and Claude Code both scan the same personal skills
  # directory (~/.claude/skills/<name>/SKILL.md) - confirmed on this host,
  # same convention as the dendritic-nix skill already symlinked there
  # manually. Only skills/typst/ is deployed, not the whole repo: the repo
  # root also carries tests/, tools/, and pixi tooling used to regenerate
  # the bundled API/package indexes upstream, none of which belongs in the
  # skill directory an agent sees.
  den.aspects.claude-skill-typst.homeManager =
    { pkgs, ... }:
    {
      # search-api.py/search-packages.py (stdlib-only, no pixi env needed
      # here) require python3 on PATH; the skill's whole point is driving
      # the typst CLI.
      home.packages = [
        pkgs.python3
        pkgs.typst
      ];

      home.file.".claude/skills/typst".source = "${inputs.claude-skill-typst}/skills/typst";
    };
}
