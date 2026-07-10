{ inputs, ... }:
{
  # pinned to the exact rev the live system was using, for a
  # behavior-preserving port
  flake-file.inputs.musnix.url =
    "github:musnix/musnix/8548782f0d1d0928daa3fffde8a008f72219a3f3";

  # real-time audio production tuning (JACK/DAW routing): performance CPU
  # governor, swappiness, audio-group udev rules/PAM limits, VST/LV2/LADSPA
  # plugin paths, plus a PREEMPT_RT kernel via kernel.realtime.
  den.aspects.musnix.nixos =
    { pkgs, ... }:
    {
      imports = [ inputs.musnix.nixosModules.default ];

      musnix.enable = true;
      musnix.rtcqs.enable = true;
      musnix.kernel.realtime = true;
      musnix.kernel.packages = pkgs.linuxPackages_latest;
    };
}
