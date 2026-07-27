# modules/ — Claude Desktop / Dispatch notes

Scoped notes for `modules/claude-desktop.nix` and the headless Dispatch setup.
See the root `README.md` for the dendritic pattern itself and this repo's
general working agreement (VM-first, no unattended `nixos-rebuild switch`).

## What this aspect actually does

`den.aspects.claude-desktop` installs Claude Desktop, plus a
`claude-desktop-headless.service` systemd user unit that runs it inside
`cage` (a kiosk Wayland compositor) so Dispatch keeps working even when
lessuseless isn't the one logged in at the console — aldair or vanya can be
on the real display via the DMS/greetd greeter with nothing visible from
this instance. Requires `linger = true` on the user (set in
`modules/users/lessuseless.nix`) so the systemd --user instance survives
without an interactive login.

## Three non-obvious fixes baked into this file — don't regress them

1. **`--user-data-dir=%h/.config/Claude-dispatch`.** Electron's
   single-instance lock is scoped to the profile directory, not the app. A
   second `claude-desktop` process on the *same* profile gets handed off
   and torn down mid-startup — this manifests as `cage: xwayland/xwm.c:592:
   xwayland_surface_destroy: Assertion ... failed` / `(EE) failed to read
   Wayland events: Broken pipe`, which looks like a crash but is actually
   two instances fighting over one profile. Giving the headless instance
   its own profile means it's fully independent of whatever you run
   interactively day to day. If you ever see that assertion, check for a
   duplicate profile before assuming something's newly broken.

2. **`WLR_RENDER_DRM_DEVICE=/dev/dri/renderD128`.** This host does NVIDIA
   PRIME offload (Intel iGPU primary, NVIDIA dGPU offload-only). Without
   this pinned, cage's headless backend enumerates and picks the NVIDIA
   node (`renderD129`) instead of Intel, which is a second, independent way
   to hit the same XWM assertion crash above. Pin it to whatever
   `readlink /dev/dri/by-path/pci-0000:00:02.0-render` resolves to on this
   host — that's the Intel node the real niri session already uses.

3. **`--password-store=gnome-libsecret`.** Chromium picks its credential
   backend by sniffing `XDG_CURRENT_DESKTOP`/`DESKTOP_SESSION`, which bare
   `cage` never sets. Without this flag it can't identify a keyring backend
   at all and silently falls back to plaintext storage — even though
   gnome-keyring is alive and its `default` collection alias is correctly
   present (verified via `gdbus call ... org.freedesktop.Secret.Service.
   ReadAlias "default"`). This is *not* a broken keyring; don't go
   debugging gnome-keyring itself if you see this complaint.

## Use the `dispatch` CLI, don't hand-roll the commands

`dispatch` (built with `pog`, defined alongside the service in this same
file) wraps all of the above:

- `dispatch --login` — visible (nested, not headless) login/re-auth against
  the `Claude-dispatch` profile; run this once initially and again if the
  session ever needs re-auth. Log in, close the window, done — the headless
  service reuses the same profile on disk.
- `dispatch --status` / `--start` / `--stop` / `--restart` — thin
  `systemctl --user` wrappers.

Before assuming the service is misconfigured, run `dispatch --status`
(or `systemctl --user status claude-desktop-headless`) and actually read the
live `ExecStart`/`Environment` off the running unit. A prior session
diagnosed a "SingletonLock on the default profile" bug from context alone
without checking — the live process was already correctly using the
`Claude-dispatch` profile the whole time. Verify against the running
process, not memory of what the file used to say.

## Known-unconfirmed

Claude Desktop's Cowork/Dispatch VM sandbox (qemu + `claude-cowork-vm.sock`
under `$XDG_RUNTIME_DIR`) does not appear to be namespaced per-profile.
Running the default-profile instance and the headless `Claude-dispatch`
instance with Cowork/Dispatch both active at the same time may collide
there — not yet confirmed either way, worth checking if Dispatch behaves
oddly with both running concurrently.

## Removed

`pinaloveMonitor` (a DMS plugin under `modules/DMS/plugins/`, wired via
`modules/DMS/monitoring.nix`) was deleted outright, not disabled — if you
see references to it in old commits, it's gone on purpose, not missing.
