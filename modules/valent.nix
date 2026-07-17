{ ... }:
{
  # Valent — KDE Connect protocol implementation built on GNOME platform libs.
  # Launches automatically via its XDG autostart entry (runs the GApplication
  # service on login). The nixos class opens the KDE Connect protocol ports so
  # paired devices can reach it.
  den.aspects.valent = {
    nixos = { ... }: {
      networking.firewall.allowedTCPPorts = [ 1716 ];
      networking.firewall.allowedUDPPorts = [ 1716 ];
    };

    homeManager = { pkgs, ... }: {
      home.packages = [ pkgs.valent ];
    };
  };
}
