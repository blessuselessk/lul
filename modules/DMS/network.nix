{ ... }:
{
  den.aspects.dms-plugins-network = {
    homeManager =
      { pkgs, ... }:
      {
        programs.dank-material-shell.plugins = {
          # Widget: manage Tailscale — connect/disconnect, switch accounts,
          # copy device IPs, pick exit nodes, manage routes, DNS, Taildrop.
          # Requires: tailscale (managed by the tailscale aspect).
          dankscale.src = pkgs.fetchFromGitHub {
            owner = "dwright134";
            repo = "dms-dankscale";
            rev = "bddebf0e2935ba23b0614ff9af5bf8f4ed6d3d9f";
            hash = "sha256-o5kcFV7VAmHJqsKgnjDuuryubnuI9U+GQIPOlENZ5ao=";
          };

          # Control-center widget: network toggle with Ethernet, WiFi,
          # and Other interfaces (bridges, VLANs, bonds).
          # Requires DMS >= 1.4.2.
          extendedNetworkToggle.src = pkgs.fetchFromGitHub {
            owner = "notherealmarco";
            repo = "dms-plugin-extended-network";
            rev = "f58b4b28391eaa6157e9b89faf9837f711315930";
            hash = "sha256-lRNdJ1eSDRNYU4fME4g11IbPFoCwb8siYB1R2gQIAck=";
          };

          # Widget: toggle Cloudflare WARP with real-time status updates.
          # Requires: warp-cli (not in nixpkgs; install via Cloudflare repo).
          warpToggle.src = pkgs.fetchFromGitHub {
            owner = "ahmed-mekky";
            repo = "dms-warp-toggle";
            rev = "3bee1e952c626071167c4e0aedad6241f7f624e0";
            hash = "sha256-SgUWuMG5bDuFbdXvWmSUfgOyiq2kX/6iovUIWITDxsE=";
          };
        };
      };
  };
}
