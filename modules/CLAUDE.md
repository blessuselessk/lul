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
   backend by sniffing `XDG_CURRENT_DESKTOP`/`DESKTOP_SESSION`. Bare `cage`
   never sets it, and — confirmed live 2026-09-21 — neither does plain
   `niri`, so this bites the *interactive* profile too, not just headless
   Dispatch. Without this flag Chromium can't identify a keyring backend at
   all and silently falls back to plaintext storage — even though
   gnome-keyring is alive and its `default` collection alias is correctly
   present (verified via `gdbus call ... org.freedesktop.Secret.Service.
   ReadAlias "default"`). This is *not* a broken keyring; don't go
   debugging gnome-keyring itself if you see this complaint. Worse than
   plaintext storage: on the interactive profile it showed up as
   `safeStorage isEncryptionAvailable=false ... tokens will not persist` —
   every restart lost the login session, which is also what was triggering
   the "No Apps Available" bug below (re-login is what walks into that
   portal handoff). As of 2026-09-21 the flag is baked into
   `claude-desktop-pkg` itself via a `symlinkJoin` + `makeWrapper` in the
   aspect's `let` block, so it applies to every invocation (interactive
   launch, `dispatch --login`, and the headless service) from one place —
   it's no longer passed ad hoc at each call site.

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

## Known bug: Google/magic-link sign-in stuck on "No Apps Available"

Symptom: clicking "Continue with Google" or a magic link opens the system
browser, the actual auth completes fine (Google issues a code / the
magic-link mail resolves), then a "Portal • Open With" dialog pops up
saying "No apps installed that can open '...<fragment>'". Canceling it does
nothing — the app has no other channel to learn sign-in succeeded, so it
just sits there waiting forever.

Root cause (confirmed live 2026-09-12 via `dbus-monitor --session
"interface='org.freedesktop.portal.OpenURI'"` while retrying): the link
Chrome tries to open is a plain, already-registered `claude://` URI, e.g.
`claude://login/google-auth?code=<google-oauth-code>&anon_id=claudeai.v1.<uuid>`.
That `<uuid>` (or, for magic-link, a base64/email fragment) is just the
`anon_id` *query parameter* value, not the URI scheme — despite how it
looks truncated in the dialog text, and despite an earlier diagnosis in
this same session wrongly concluding it was some dynamically-generated
per-attempt scheme. `xdg-mime query default x-scheme-handler/claude`
resolves correctly to `com.anthropic.Claude.desktop` the whole time. The
actual bug is that `xdg-desktop-portal-gnome`'s AppChooser fails to
resolve `claude://` to that already-correct handler and falls through to
"No Apps Available" instead of just launching it. Matches
aaddrick/claude-desktop-debian#121 ("Google login spinner hangs forever")
— same handoff failure, different visible symptom depending on which
portal backend answers.

Manual fix (works every time tried so far; the capture step is
time-sensitive since `code=` is a single-use Google OAuth code — act
within a minute or two of catching it):

```console
# 1. Start watching before retrying:
dbus-monitor --session "interface='org.freedesktop.portal.OpenURI'"

# 2. Retry the sign-in (Google or magic link) in Claude Desktop. The full
#    claude://... URI appears as a `string` argument on the OpenURI method
#    call the instant Chrome attempts the handoff — grab it from the
#    dbus-monitor output before the "No Apps Available" dialog even
#    finishes rendering.

# 3. Replay it straight to the already-running instance. Electron's
#    single-instance lock hands the argv to the open window over IPC and
#    this process exits almost immediately — that quick exit is the sign
#    the handoff worked, not a failure:
claude-desktop 'claude://login/google-auth?code=...&anon_id=...'
```

Untested for the headless Dispatch profile specifically — would presumably
need `--user-data-dir=%h/.config/Claude-dispatch` added to the replay
command the same way `dispatch --login` scopes to that profile.

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
