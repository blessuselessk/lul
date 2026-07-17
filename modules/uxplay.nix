{ den, ... }:
{
  # AirPlay mirroring server. Avahi provides the mDNS/DNS-SD advertisements
  # that let Apple devices discover the UxPlay receiver on the local network.
  den.aspects.uxplay = {
    nixos = { pkgs, ... }: {
      environment.systemPackages = [ pkgs.uxplay ];

      # 7000/7001: AirPlay control; 7100-7102: pinned media stream ports (-p 7100)
      networking.firewall.allowedTCPPorts = [ 7000 7001 7100 7101 7102 ];
      networking.firewall.allowedUDPPorts = [ 6000 6001 7011 7100 7101 7102 ];

      services.avahi = {
        enable = true;
        nssmdns4 = true;
        publish.enable = true;
        publish.userServices = true;
      };
    };

    # Runs uxplay as a systemd user service with pinned streaming ports so they
    # don't change between sessions and the firewall rules above stay valid.
    homeManager = { pkgs, ... }: {
      systemd.user.services.uxplay = {
        Unit.Description = "UxPlay AirPlay receiver";
        Unit.After = [ "graphical-session.target" ];
        Service = {
          ExecStart = "${pkgs.uxplay}/bin/uxplay -p 7100";
          Restart = "on-failure";
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
