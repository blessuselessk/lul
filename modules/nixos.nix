{ den, ... }:
{
  # host aspect
  den.aspects.nixos = {
    includes = [
      den.batteries.hostname
      den.aspects.niri
      den.aspects.dank-material-shell
      den.aspects.musnix
      den.aspects.handy
      den.aspects.printing
      den.aspects.audio
      den.aspects.firefox
    ];

    # `includes` only pulls each aspect's `nixos` class into the host - the
    # `homeManager` class is a separate resolution scoped to users, so niri's
    # and dank-material-shell's home-manager companions have to be forwarded
    # to this host's users explicitly.
    provides.to-users.homeManager = {
      imports = [
        den.aspects.niri.homeManager
        den.aspects.dank-material-shell.homeManager
      ];
    };

    nixos =
      { ... }:
      {
        nix.settings.experimental-features = [ "nix-command" "flakes" ];

        boot.loader.systemd-boot.enable = true;
        boot.loader.efi.canTouchEfiVariables = true;

        boot.kernelParams = [
          # Prevent NVMe controller from autonomously transitioning into deep
          # non-operational power states (PS3/PS4, up to 45ms exit latency) -
          # suspected cause of "Disabling device after reset failure: -19"
          # drops + forced-RO btrfs panics.
          "nvme_core.default_ps_max_latency_us=0"
          # Force-probe the Xe graphics driver for this device ID.
          "xe.force_probe=9a49"
        ];

        networking.networkmanager.enable = true;

        time.timeZone = "America/Mexico_City";
        i18n.defaultLocale = "en_US.UTF-8";
      };
  };
}
