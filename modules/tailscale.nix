{
  den.aspects.tailscale.nixos = {
    services.tailscale.enable = true;
    # Lets costacombat (no sudo) drive tailscaled from the DMS dankscale
    # widget: connect, log in, switch tailnets. Tailscale allows only one
    # operator; lessuseless was it before and still has sudo.
    services.tailscale.extraSetFlags = [ "--operator=costacombat" ];
    # Allow Tailscale traffic through the firewall (includes MagicDNS, DERP,
    # and direct peer connections). Without this, tailscale up succeeds but
    # packets from peers are silently dropped by the default INPUT REJECT rule.
    networking.firewall.trustedInterfaces = [ "tailscale0" ];
  };
}
