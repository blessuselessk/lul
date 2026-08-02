{ den, inputs, ... }:
{
  # host aspect
  den.aspects.hornicorn = {
    includes = [
      den.batteries.hostname
      den.aspects.niri
      den.aspects.dank-material-shell
      den.aspects.printing
      den.aspects.audio
      den.aspects.web-browsers
      den.aspects.tailscale
      den.aspects.niri-use-rs
      den.aspects.uxplay
      den.aspects.valent
      den.aspects.dms-plugins-first-party
      den.aspects.dms-plugins-audio
      den.aspects.dms-plugins-monitoring
      den.aspects.dms-plugins-network
      den.aspects.dms-plugins-productivity
      den.aspects.dms-plugins-desktop
      den.aspects.dms-plugins-hardware
      den.aspects.dms-plugins-bar-ux
      den.aspects.fingerprint
      den.aspects.vm
      den.aspects.talon
      den.aspects.skill-builder
    ];

    # `includes` only pulls each aspect's `nixos` class into the host - the
    # `homeManager` class is a separate resolution scoped to users, so niri's
    # and dank-material-shell's home-manager companions have to be forwarded
    # to this host's users explicitly.
    provides.to-users.homeManager = {
      imports = [
        den.aspects.niri.homeManager
        den.aspects.dank-material-shell.homeManager
        den.aspects.nix-direnv.homeManager
        den.aspects.valent.homeManager
        den.aspects.uxplay.homeManager
        den.aspects.dms-plugins-first-party.homeManager
        den.aspects.dms-plugins-audio.homeManager
        den.aspects.dms-plugins-monitoring.homeManager
        den.aspects.dms-plugins-network.homeManager
        den.aspects.dms-plugins-productivity.homeManager
        den.aspects.dms-plugins-desktop.homeManager
        den.aspects.dms-plugins-hardware.homeManager
        den.aspects.dms-plugins-bar-ux.homeManager
        den.aspects.talon.homeManager
      ];
    };

    nixos =
      { config, lib, pkgs, ... }:
      let
        pog = inputs.pog.packages.${pkgs.stdenv.hostPlatform.system}.pog.pog;

        # One-shot rebuild + Cachix push. Runs the remote-flake switch (so
        # the closure is fetched from Cachix, not built locally), then pushes
        # any paths that CI skipped (currently: voxtype-vulkan, which is gated
        # out of CI because GPU variants need hardware-specific runtime deps
        # GitHub runners don't expose). Cachix deduplicates, so pushing the
        # full closure is safe — it only uploads what isn't already cached.
        hornicorn-rebuild = pog {
          name = "hornicorn-rebuild";
          description = "Switch hornicorn from the remote flake, then push locally-built paths to Cachix";
          # errexit+pipefail (pog-native, not hand-rolled) so a failing
          # nixos-rebuild aborts the script instead of falling through to an
          # unconditional Cachix push.
          strict = true;
          flags = [
            {
              name = "no-push";
              bool = true;
              description = "Skip the Cachix push after a successful switch";
            }
          ];
          script = helpers: with helpers; ''
            # DMS's niri.nix warns any time enableKeybinds + includes.enable
            # (default true) are both set, regardless of "binds" already
            # being excluded from includes.filesToInclude - a known
            # false-positive for this repo's setup (see dank-material-shell.nix).
            # Filtered here rather than system-wide so other future warnings
            # still surface. `strict`'s pipefail keeps a real nixos-rebuild
            # failure from being swallowed by the grep stage.
            #
            # --refresh: this is unpinned github:blessuselessk/lul, and root's
            # Nix fetcher cache (separate from the interactive user's - `sudo`
            # runs under its own cache) will silently reuse a stale resolution
            # within tarball-ttl (default 1h). Without this, a switch can
            # report success while rebuilding the exact same old commit -
            # confirmed happening twice in practice before this was added.
            # shellcheck disable=SC2016
            sudo nixos-rebuild switch --refresh --flake github:blessuselessk/lul#hornicorn 2>&1 | grep -Ev '^evaluation warning: .* profile: It is not recommended to use both `enableKeybinds` and `includes\.enable` at the same time\.$'

            if ! ${flag "no_push"}; then
              echo "Pushing locally-built paths to lul.cachix.org (already-cached paths are skipped)..."
              nix path-info --recursive /run/current-system | cachix push lul
            fi
          '';
        };

        # VM-verify the same remote-flake build hornicorn-rebuild would
        # switch to, before actually touching real hardware - the README's
        # documented workflow. Uses `nixos-rebuild build-vm` rather than
        # `nix run .#vm` (modules/vm.nix) so it tests the exact post-CI
        # commit on GitHub instead of the local working tree, matching what
        # hornicorn-rebuild itself would apply. build-vm needs no sudo, so
        # unlike hornicorn-rebuild this one is safe to run from a context
        # with no controlling TTY (confirmed: the agent's shell can't drive
        # hornicorn-rebuild's fingerprint/sudo prompt at all - see README).
        hornicorn-rebuild-vm = pog {
          name = "hornicorn-rebuild-vm";
          description = "Build hornicorn's config as a VM from the remote flake and boot it, without touching real hardware";
          strict = true;
          script = helpers: with helpers; ''
            # shellcheck disable=SC2016
            nixos-rebuild build-vm --refresh --flake github:blessuselessk/lul#hornicorn 2>&1 | grep -Ev '^evaluation warning: .* profile: It is not recommended to use both `enableKeybinds` and `includes\.enable` at the same time\.$'
            ./result/bin/run-hornicorn-vm
          '';
        };
      in
      {
        imports = [
          # Machine-specific hardware config for the ThinkPad P14s Gen 2i:
          # sets up NVIDIA T500 PRIME offload (PCI:1:0:0) with Intel Xe iGPU
          # (PCI:0:2:0) as the display driver, Tiger Lake CPU tuning, Intel
          # VAAPI, fstrim, and TLP (suppressed here since DMS manages
          # power-profiles-daemon instead).
          inputs.nixos-hardware.nixosModules.lenovo-thinkpad-p14s-intel-gen2
        ];

        nix.settings.experimental-features = [ "nix-command" "flakes" ];

        nix.settings.substituters = [ "https://lul.cachix.org" "https://niri.cachix.org" ];
        nix.settings.trusted-public-keys = [
          "lul.cachix.org-1:du306UACvYmVfHgEtPd2XoPszPmgB9UyWk3iB+6ZYwE="
          "niri.cachix.org-1:Wv0OmO7PsuocRKzfDoJ3mulSl7Z6oezYhGhR+3W2964="
        ];

        environment.systemPackages = [ pkgs.cachix hornicorn-rebuild hornicorn-rebuild-vm ];

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
        # iwlwifi (AX201) enters a bad state under NM's default power-save
        # mode: scan requests start returning -EINVAL, NM responds by rfkill
        # soft-blocking the interface, triggering the disappear/reappear loop.
        networking.networkmanager.wifi.powersave = false;

        time.timeZone = "America/Mexico_City";
        i18n.defaultLocale = "en_US.UTF-8";

        # nixos-hardware's Intel GPU module defaults to the i915 driver, but
        # Linux 7.0 uses xe for Tiger Lake (9a49). Tell it so it puts xe in
        # the initrd instead of the now-absent i915.
        hardware.intelgpu.driver = "xe";

        # nixos-hardware handles offload mode and bus IDs; we add the pieces
        # it intentionally leaves to the user.
        hardware.nvidia = {
          # Required for Wayland/niri — enables GBM backend on the NVIDIA side.
          modesetting.enable = true;
          # Power off the dGPU when no PRIME offload client holds it. nixos-
          # hardware enables powerManagement but not finegrained by default.
          powerManagement.enable = true;
          powerManagement.finegrained = true;
          package = config.boot.kernelPackages.nvidiaPackages.stable;
        };

        # nixos-hardware's P14s module sets videoDrivers = ["modesetting"]
        # (overriding the mkDefault ["nvidia"] in common/gpu/nvidia/default.nix),
        # which causes hardware.nvidia.enabled to derive as false — silently
        # disabling the entire nvidia module so nouveau loads instead. Force
        # "nvidia" in so the proprietary driver and kernel modules are built.
        # PRIME offload still routes display output through the Intel iGPU.
        services.xserver.videoDrivers = lib.mkForce [ "nvidia" ];

        # Required by dms-battery-plus, wireplumber, and battery status tooling.
        # Also indirectly needed for the UCSI USB-C PD stack — the NVIDIA PRH
        # (platform request handler) talks to the ThinkPad EC which also owns
        # the UCSI controller; upower keeps that path exercised correctly.
        services.upower.enable = true;
      };
  };
}
