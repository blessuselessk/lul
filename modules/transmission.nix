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
      };
    };
}
