# Regression test for the fix in dank-material-shell.nix
# (security.pam.services.greetd.enableGnomeKeyring). Deliberately does NOT
# reuse nixosConfigurations.hornicorn - that config's hardware-configuration.nix
# (disk UUIDs, NVIDIA prime, etc.) doesn't translate to a nixosTest's abstracted
# hardware, and pulling in the full DMS/QuickShell greeter would make this test
# slow and give it many unrelated failure modes. What's actually under test is
# PAM/greetd mechanics, which don't depend on which greeter frontend collects
# the password: greetd's own nixpkgs module always runs its *internal*
# session-launch PAM transaction through a service literally named "greetd"
# (see services/display-managers/greetd.nix - `auth substack login`),
# regardless of whether the visible prompt came from DMS's quickshell UI or
# greetd's bundled text greeter, agreety, used here. So agreety is a faithful,
# much lighter stand-in for this specific fix.
{
  perSystem =
    { pkgs, ... }:
    {
      checks.greetd-gnome-keyring-unlock = pkgs.testers.nixosTest {
        name = "greetd-gnome-keyring-unlock";

        nodes.machine =
          { pkgs, ... }:
          {
            services.greetd = {
              enable = true;
              settings.default_session = {
                command = "${pkgs.greetd}/bin/agreety --cmd ${
                  pkgs.writeShellScript "session-marker" ''
                    touch /tmp/session-started
                    sleep infinity
                  ''
                }";
                user = "greeter";
              };
            };

            services.gnome.gnome-keyring.enable = true;
            # The fix under test.
            security.pam.services.greetd.enableGnomeKeyring = true;

            users.users.alice = {
              isNormalUser = true;
              password = "test";
            };

            environment.systemPackages = [ pkgs.glib ]; # gdbus, for the assertion
          };

        testScript = ''
          # agreety runs attached to VT1 (services.greetd.settings.terminal.vt),
          # not the serial console - wait_for_console_text only watches the
          # -serial stdio stream (ttyS0), so it never sees VT1's prompts and
          # blocks forever. /dev/vcs1 is the kernel's screen-dump device for
          # VT1's actual rendered content, readable through the backdoor root
          # shell (machine.succeed), independent of the serial console.
          # send_chars itself is fine either way - it injects real
          # virtio-keyboard events, which the kernel routes to whichever VT is
          # active, so it reaches agreety's stdin regardless of which console
          # we're reading from.
          machine.wait_for_unit("multi-user.target")
          machine.wait_until_succeeds("cat /dev/vcs1 | grep -q 'login:'")
          machine.send_chars("alice\n")
          machine.wait_until_succeeds("cat /dev/vcs1 | grep -q 'Password:'")
          machine.send_chars("test\n")
          machine.wait_for_file("/tmp/session-started")

          uid = machine.succeed("id -u alice").strip()
          machine.wait_for_file(f"/run/user/{uid}/bus")

          # Must run as alice, not root: machine.succeed's backdoor shell is
          # root, and a per-user session bus only accepts connections from
          # its own uid - dbus-broker slams the connection shut on a
          # cross-uid peer during credential-passing ("Error sending
          # credentials"/"Connection reset by peer"), which looks identical
          # to a bus-not-ready race but never resolves no matter how long you
          # retry as root.
          #
          # runuser on its own isn't enough either - each invocation opens a
          # brand new PAM session rather than joining alice's existing
          # greetd-launched one, so DBUS_SESSION_BUS_ADDRESS isn't set, and
          # gdbus/glib fall back to X11-style `dbus-launch --autolaunch`,
          # which fails outright with no X server ("Child process exited
          # with code 1"). Has to be pointed at the real bus explicitly.
          gdbus_cmd = (
              "runuser -u alice -- env "
              f"DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/{uid}/bus "
              "gdbus call --session --dest org.freedesktop.secrets "
              "--object-path /org/freedesktop/secrets/collection/login "
              "--method org.freedesktop.DBus.Properties.Get "
              "org.freedesktop.Secret.Collection Locked"
          )
          # Even as alice, org.freedesktop.secrets (provided by gnome-keyring)
          # can still be mid-registration for a moment right after the bus
          # starts - retry instead of asserting on the first attempt.
          machine.wait_until_succeeds(gdbus_cmd)
          locked = machine.succeed(gdbus_cmd)
          assert "true" not in locked, f"login keyring is still locked after password login: {locked}"
        '';
      };
    };
}
