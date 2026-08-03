# lul

Personal NixOS configuration for host `nixos`, user `lessuseless`: niri
(Wayland compositor) + [Dank Material Shell](https://github.com/AvengeMedia/DankMaterialShell)
as the desktop, built on the [dendritic pattern](https://github.com/vic/dendrix)
via [den](https://den.denful.dev).

Migrated from a traditional `/etc/nixos/configuration.nix` — see
[Migration notes](#migration-notes) for what changed in the process.

## Built with Claude Code

This repository is developed collaboratively with [Claude Code](https://claude.com/claude-code)
as a hands-on pair, not just a one-shot generator. In practice that means:

- **Nothing gets applied to the real machine without the fingerprint gate.**
  Every change is verified in a disposable VM first — either `nix run .#vm`
  (local tree) or `hornicorn-rebuild-vm` (the exact remote-flake commit CI
  just built) — booted and exercised before it's a candidate for
  `nixos-rebuild switch` on actual hardware. The agent's shell has no
  controlling TTY by default, so a bare `sudo` inside it fails outright
  (`Verification timed out` / `sudo: a terminal is required`) - confirmed by
  testing. Wrapping the call in a real pty (`script -qec "hornicorn-rebuild"
  /dev/null`) fixes the plumbing and lets PAM's fingerprint prompt wait its
  normal window, so the agent *can* drive `hornicorn-rebuild` this way - but
  the fingerprint reader is still the actual authority: no NOPASSWD sudoers
  rule exists, so a switch only goes through if a human touches the sensor
  in time. On CI green, the loop verifies via `hornicorn-rebuild-vm`, then
  attempts `hornicorn-rebuild` up to 3 times (30s apart) waiting on that
  touch, and stops with a loud notification if all 3 time out.
- **Debugging is iterative and shown, not hidden.** Root causes were tracked
  down through direct log/binary inspection (`niri validate`, reading
  `journalctl` output, diffing rendered configs) rather than guessing —
  several comments in this repo document a specific failure mode and how it
  was actually diagnosed, not just the fix.
- **Comments explain *why*, not *what*.** Where you see a comment next to an
  option, it's almost always recording a non-obvious constraint or a bug
  that would otherwise resurface (e.g. why `useUserPackages` is needed, or
  why one specific quickshell package reference has to be overridden
  alongside two others).
- **The commit history is real project history**, not a single squashed
  "initial commit" — it reflects the actual sequence of decisions.

If something here looks over-explained, that's deliberate: the comments are
load-bearing documentation for future sessions (human or agent) picking the
config back up.

## The pattern, in this repo's own terms

Dendritic organizes config around **aspects** (a cross-cutting feature, e.g.
`niri`, `audio`, `firefox`) instead of the traditional "one file per host."
Each aspect can configure multiple **classes** — `nixos` (system-level) and
`homeManager` (per-user) are the two used here. This is the opposite axis
from a normal config: files are named after *what they configure*, not
*where they apply*.

```nix
# modules/firefox.nix — the whole file
{
  den.aspects.firefox.nixos.programs.firefox.enable = true;
}
```

```nix
# modules/niri.nix — one aspect, two classes
den.aspects.niri = {
  nixos      = { pkgs, ... }: { programs.niri.enable = true; ... };
  homeManager = { ... }: { programs.niri.settings.binds = { ... }; ... };
};
```

[**den**](https://den.denful.dev) sits on top of the plain dendritic layer
and adds *entities* (hosts/users) and *context-driven* aspects — an aspect
can be a function of `{ host, user }`, and den only calls it where that
context actually exists. This repo's host and user are declared once, in
one line each:

```nix
# modules/hosts.nix
den.hosts.x86_64-linux.nixos.users.lessuseless = { };
```

Every other module attaches to `den.aspects.<name>` and gets pulled in via
an `includes` list on the host aspect (`modules/nixos.nix`) — adding a new
feature to the system means writing one new aspect file and adding its name
to that one list.

### Vocabulary used in this repo

| Term | Meaning here |
|---|---|
| **aspect** | One feature, one file: `niri`, `dank-material-shell`, `musnix`, `handy`, `printing`, `audio`, `firefox`, plus the host aspect (`nixos`) and user aspect (`lessuseless`) itself |
| **class** | `nixos` (system config) or `homeManager` (per-user config) — the two evaluation domains an aspect can target |
| **includes** | Dependency list on the host aspect (`modules/nixos.nix`) pulling in every feature aspect's `nixos` class |
| **provides** | Cross-entity delivery — `provides.to-users.homeManager` on the host aspect forwards niri's and Dank Material Shell's `homeManager` class to every user on the host, since `includes` alone only reaches the `nixos` class |
| **battery** | A den-provided helper for common patterns — `den.batteries.hostname`, `define-user`, `primary-user` are used here instead of hand-rolling user/hostname wiring |
| **import-tree** | Every `.nix` file under `modules/` is auto-imported; `flake.nix` itself contains no logic, only the entrypoint and inputs |

### Repo layout

```
flake.nix                        # generated manifest ONLY — never hand-edit (nix run .#write-flake)
modules/
  dendritic.nix                  # bootstrap: wires flake-file + den's flakeModules
  defaults.nix                   # den.default.* — stateVersion, allowUnfree, etc.
  hosts.nix                      # the one line declaring host `nixos` + user `lessuseless`
  nixos.nix                      # host aspect: includes every feature aspect, forwards homeManager companions
  hardware-configuration.nix     # hardware scan, contributes to the SAME nixos.nixos class as nixos.nix
  lessuseless.nix                # user aspect: batteries + user-specific settings
  niri.nix                       # niri compositor + upstream default keybinds
  dank-material-shell.nix        # DMS bar/launcher/notifications/lock/greeter for niri
  musnix.nix, handy.nix,
  printing.nix, audio.nix,
  firefox.nix                    # one small aspect each
  nh.nix                         # exposes `nh`-compatible build apps (template-provided)
  vm.nix                         # `nix run .#vm` tooling + VM-only test password
```

Multiple files are allowed to contribute to the same aspect/class — den
merges them like any other NixOS module (`nixos.nix` and
`hardware-configuration.nix` both write to `den.aspects.nixos.nixos`, kept
separate because they came from separate concerns in the original config).

## Building & testing

```console
# verify the flake evaluates and its generated flake.nix is up to date
nix flake check

# build the system closure without switching anything
nix run .#nixos

# boot it in a disposable VM instead — the recommended way to test changes
nix run .#vm

# only once verified in the VM: apply for real (not run by the agent)
sudo nixos-rebuild switch --flake .#nixos
```

The VM defaults to software rendering; if you need to test niri actually
compositing (not just booting), you may need extra QEMU display flags — see
`modules/vm.nix` for the current invocation used during development.

## Migration notes

Ported from a traditional, non-flake `/etc/nixos/configuration.nix` running
KDE Plasma6/SDDM. Two intentional scope changes were made along the way:
niri + Dank Material Shell replaced Plasma6/SDDM.

Two non-obvious bugs surfaced during the port and are documented where they
were fixed rather than repeated here: a home-manager package-install bug
that silently prevented config changes from ever taking effect
(`modules/niri.nix`, `useUserPackages`), and a version mismatch between
nixpkgs' packaged `quickshell` and what Dank Material Shell's UI actually
requires (`modules/dank-material-shell.nix`) — both took direct log
inspection inside a test VM to actually pin down.

## Further reading

- [den documentation](https://den.denful.dev) — the layer this config is
  built on (entities, aspects, policies, batteries)
- [dendrix](https://github.com/vic/dendrix) — the dendritic pattern this
  repo follows, and a registry of shareable community aspects
