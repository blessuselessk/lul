{ ... }:
{
  den.aspects.transmission.nixos =
    { pkgs, ... }:
    {
      services.transmission = {
        enable = true;
        # Explicit even though stateVersion 26.05 (defaults.nix) already
        # resolves here on its own - nixpkgs only auto-selects transmission_4
        # via a stateVersion >= 25.11 check (transmission_3 was dropped
        # outright in 24.11, see nixos/modules/services/torrent/
        # transmission.nix). Pinning it directly means this aspect keeps
        # working even if that gating logic ever changes upstream.
        package = pkgs.transmission_4;

        # RPC/web UI (http://127.0.0.1:9091) stays on its 127.0.0.1 default,
        # and openRPCPort stays false - no firewall rule opened for it, on
        # tailscale0 or otherwise. Reach it via an SSH tunnel
        # (ssh -L 9091:localhost:9091 hornicorn) rather than exposing it on
        # the tailnet or LAN.

        # Incoming peer connections aren't blocked host-side by this alone;
        # still requires forwarding TCP+UDP 51413 on the router for full
        # connectivity from outside the LAN.
        openPeerPorts = true;

        # Keep downloads inside the daemon's own state directory rather than
        # pointing download-dir at something under /home. The systemd
        # sandbox (RootDirectory= + BindPaths=, see the upstream module)
        # only binds this exact path into the daemon's mount namespace -
        # pointing it elsewhere means fighting that sandbox instead of
        # using it. Browse the files from the home directory via the
        # bind-mounted symlink below instead.
        settings.download-dir = "/var/lib/transmission/Downloads";
      };

      # /var/lib/transmission/Downloads is created by the transmission
      # service itself (StateDirectory, mode 750, owned by
      # transmission:transmission) - members of the "transmission" group
      # (see modules/users/lessuseless.nix) can read it. This just makes it
      # reachable from the home directory without moving it into the
      # sandboxed daemon's home.
      systemd.tmpfiles.rules = [
        "L+ /home/lessuseless/Downloads/Torrents - - - - /var/lib/transmission/Downloads"
      ];
    };
}
