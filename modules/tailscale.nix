{
  den.aspects.tailscale.nixos = {
    services.tailscale.enable = true;
    # Allow Tailscale traffic through the firewall (includes MagicDNS, DERP,
    # and direct peer connections). Without this, tailscale up succeeds but
    # packets from peers are silently dropped by the default INPUT REJECT rule.
    networking.firewall.trustedInterfaces = [ "tailscale0" ];
  };
}
