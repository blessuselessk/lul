# Local default: CI = false. The GitHub Actions build-systems workflow
# overwrites this file with { _module.args.CI = true; } before running
# nix build. Since this file is git-tracked, the overwrite makes it a
# "modified tracked file" — nix sees it even in a dirty worktree. An
# untracked file (as was the approach before) is invisible to nix's
# git-archive-style source filtering.
{ _module.args.CI = false; }
