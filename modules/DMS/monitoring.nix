{ ... }:
let
  # sshMonitor lives in a subdir of the boutabong mono-repo.
  boutabong = {
    rev = "6ec6381e0d80f07f8d7b902896e98c6ad8658017";
    hash = "sha256-nMk9Ab++JFJ2vwDaWSdFFLDWVVPiLcqPDjb0fY/xKoc=";
  };
  # uptimeBar lives in a subdir of the viewerofall-labs weather-viewer repo.
  viewerofall = {
    rev = "45ab60d67079d23b5c1fbac506aec825e9d3178c";
    hash = "sha256-nD+/+iGNi5z0iJ8s0c3WfwDNzOVmW4U7w6SLAnZv3k4=";
  };
in
{
  den.aspects.dms-plugins-monitoring = {
    homeManager =
      { pkgs, ... }:
      let
        boutabongRepo = pkgs.fetchFromGitHub {
          owner = "boutabong";
          repo = "dms-plugins";
          inherit (boutabong) rev hash;
        };
        viewerofallRepo = pkgs.fetchFromGitHub {
          owner = "viewerofall-labs";
          repo = "weather-viewer";
          inherit (viewerofall) rev hash;
        };
      in
      {
        programs.dank-material-shell.plugins = {
          # Widget: AI API quota, billing, auth, and local usage telemetry.
          # Requires: bash, jq, curl.
          aiOverviewControl.src = pkgs.fetchFromGitHub {
            owner = "bernardopg";
            repo = "AiOverviewControl";
            rev = "baa3f6ba097133a5aef45faaca58929a217d7539";
            hash = "sha256-9vhtM5JzsqYuBK/0k5O6460bTmnwv5OhTMW7UzoVLUw=";
          };

          # Widget: disk, ZFS pool, and Nix store usage with visual indicators.
          dankDiskUsage.src = pkgs.fetchFromGitHub {
            owner = "alcxyz";
            repo = "DankDiskUsage";
            rev = "d53fb4e6b90324c6b8de7f75fd0cbacb84ef3193";
            hash = "sha256-Na5WvZENGE6bo5z+y78s8BGKUkSqYs4pklAAuO76Ed0=";
          };

          # Widget: NVIDIA GPU load as an animated progress bar.
          gpuMonitor.src = pkgs.fetchFromGitHub {
            owner = "rollecode";
            repo = "dms-gpu-monitor";
            rev = "8ce8003effdc5fd5c47a7a47ab08ee6375223ccf";
            hash = "sha256-6zakNjkd31cMpgEJV/zvGx5Mu5qtsCJYK81PrQrLYKE=";
          };

          # Widget: home-manager generations and Nix store disk usage
          # with cleanup capabilities.
          nixMonitor.src = pkgs.fetchFromGitHub {
            owner = "antonjah";
            repo = "nix-monitor";
            rev = "ef3db9d5a525ddf41355e8c456b40d56480a6626";
            hash = "sha256-lTbQ13lQ3ZPNkdnFmxAMGf1Gjx//80lDDlcJR8msREI=";
          };

          # Widget: NVIDIA GPU usage, VRAM, and temperature.
          # Requires: nvidia-smi.
          nvidiaGpuMonitor.src = pkgs.fetchFromGitHub {
            owner = "TEJASJONDHALE";
            repo = "dms-nvidia-gpu-monitor";
            rev = "d1e05ade7122d714ffdf6a242d892db8690b016e";
            hash = "sha256-vUsMgyLiSNr+1reRi0ytEolFbsA553NtZlKmO5jx858=";
          };

          # Desktop overlay: live process monitoring with grouping, sorting,
          # and scope filters. Requires: dgop (managed by DMS module).
          processList.src = pkgs.fetchFromGitHub {
            owner = "Mithgroth";
            repo = "dms-process-list";
            rev = "83711c4022b50674d1076f218d8a54a1e82873e6";
            hash = "sha256-PQdERKd58SlKIbe9fGPFKuQvueEmlHecK00UXuesXVE=";
          };

          # Widget: RAM usage as an animated progress bar.
          ramMonitor.src = pkgs.fetchFromGitHub {
            owner = "rollecode";
            repo = "dms-ram-monitor";
            rev = "dec31c4dff0bb9e2273a8109d875bfb90c97adbe";
            hash = "sha256-d63mOZlvop8V8JeRxGmFGYHIW+UP8fnOO3nLu7hSwWg=";
          };

          # Widget: monitor active SSH, SFTP, FTP, and Yazi VFS connections.
          sshMonitor.src = "${boutabongRepo}/SSH-Monitor";

          # Widget: system uptime displayed in a compact bubble.
          # Requires DMS >= 1.4.0.
          uptimeBar.src = "${viewerofallRepo}/uptimeBar";

          # Widget: NVIDIA VRAM usage as an animated progress bar.
          vramMonitor.src = pkgs.fetchFromGitHub {
            owner = "rollecode";
            repo = "dms-vram-monitor";
            rev = "e00c64191236db756f375e73bced3227c26035cd";
            hash = "sha256-L7cZ7ztAN7m3ibimto1qfT8xZZsH10RNwM18MN2+CH8=";
          };
        };
      };
  };
}
