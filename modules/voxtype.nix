{ inputs, lib, CI ? false, ... }:
{
  flake-file.inputs.voxtype = {
    url = "github:peteonrails/voxtype";
    # Intentionally NOT following our nixpkgs — voxtype uses its own pinned
    # nixpkgs so the binary derivation only changes when voxtype's flake.lock
    # changes, not on every nixpkgs update in this repo.
  };

  # voxtype aspect — push-to-talk voice-to-text daemon (Whisper, local, no
  # telemetry). Speak; transcribed text is typed at the cursor via wtype.
  #
  # The .vulkan package is excluded from CI — voxtype's own CI does the same
  # (see build-nix.yml: "GPU variants excluded because they require unfree
  # allowlists and/or hardware-specific runtime deps that GitHub-hosted runners
  # don't expose"). CI is captured from the flake-parts closure (ci-runtime.nix
  # sets _module.args.CI = true) rather than passed as a NixOS/HM module arg.
  # Imports are unconditional (can't gate them on CI — circular dep with
  # _module.args in the inner module system), but all config is guarded by
  # lib.mkIf (!CI) so nothing is built in CI.
  den.aspects.voxtype = {
    nixos =
      { pkgs, ... }:
      {
        imports = [ inputs.voxtype.nixosModules.default ];

        config = lib.mkIf (!CI) {
          programs.voxtype = {
            enable = true;
            package = inputs.voxtype.packages.${pkgs.stdenv.hostPlatform.system}.vulkan;
          };
        };
      };

    homeManager =
      { pkgs, ... }:
      {
        imports = [ inputs.voxtype.homeManagerModules.default ];

        config = lib.mkIf (!CI) {
          home.packages = [
            pkgs.wtype # Wayland typing backend (preferred; best Unicode/CJK)
            pkgs.dotool # uinput fallback with XKB layout support
            # OSD frontend binary: voxtype-osd (already in the vulkan package)
            # dispatches to this based on PATH / osd.frontend setting.
            inputs.voxtype.packages.${pkgs.stdenv.hostPlatform.system}.osd-gtk4
          ];

          programs.voxtype = {
            enable = true;
            # Vulkan GPU inference via the Intel Xe iGPU (primary display adapter
            # in the PRIME offload config). Faster than CPU Whisper; doesn't
            # require the NVIDIA dGPU to be active.
            package = inputs.voxtype.packages.${pkgs.stdenv.hostPlatform.system}.vulkan;
            engine = "whisper";
            # large-v3-turbo: best speed/quality tradeoff in the Whisper family.
            # The daemon downloads it automatically on first start. base.en was
            # too lossy for reliable transcription; large-v3-turbo is ~10x
            # larger but the Vulkan backend on Intel Xe handles it without
            # noticeable latency.
            model.name = "large-v3-turbo";
            # Runs as a systemd user service under graphical-session.target,
            # ordered after pipewire.service.
            service.enable = true;
            settings = {
              # Keep the built-in evdev hotkey enabled. The user is already in
              # the `input` group (lessuseless.nix), so ScrollLock works for
              # PTT out of the box on Wayland without compositor cooperation.
              # Niri doesn't support release binds, so the compositor-keybind
              # PTT pattern from the voxtype README isn't achievable via niri's
              # bind system. The Mod+B toggle below is a press-once-to-start,
              # press-again-to-stop alternative for cases where ScrollLock
              # isn't convenient.
              hotkey.enabled = true;
              # voxtype-osd launcher (in the vulkan package) dispatches to the
              # osd-gtk4 frontend binary we install separately above.
              osd.enabled = true;
              # Pin to the rnnoise virtual source (echo cancel → noise suppress
              # chain configured in audio.nix) rather than the raw mic.
              audio.device = "rnnoise-source";
              # Let the NVIDIA dGPU sleep between transcriptions — Vulkan
              # inference runs on Intel Xe (PRIME offload primary), so the
              # dGPU doesn't need to stay awake for it.
              whisper.gpu_isolation = true;
            };
          };

          # Mod+B: toggle recording (press to start, press again to stop).
          # True hold-to-talk isn't possible in niri — it has no release-bind
          # mechanism — so ScrollLock via the evdev hotkey above is the PTT path.
          programs.niri.settings.binds = {
            "Mod+B".repeat = false;
            "Mod+B".action.spawn = [
              "voxtype"
              "record"
              "toggle"
            ];
          };
        };
      };
  };
}
