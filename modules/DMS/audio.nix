{ ... }:
{
  den.aspects.dms-plugins-audio = {
    homeManager =
      { pkgs, ... }:
      {
        programs.dank-material-shell.plugins = {
          # Daemon: inhibit idle when audio is playing.
          audioInhibit.src = pkgs.fetchFromGitHub {
            owner = "insecure";
            repo = "dms-audio-inhibit";
            rev = "eefccb20299d8d79089d3d976ca1505ae16d3e27";
            hash = "sha256-G3vBoFlixUqyaGUG6zjtAvYq95Y9eH5b4g/yZnkqCgs=";
          };

          # Widget: switch audio ports on a 3.5mm combo jack
          # (internal mic vs headset mic). Requires pactl.
          audioPortSwitcher.src = pkgs.fetchFromGitHub {
            owner = "osvaldx";
            repo = "Audio-Port-Switcher";
            rev = "c09de3433fce36f250625c3ac7ce7dcda8c17fee";
            hash = "sha256-Wptq7kQsl7y1ogiSMI2x6KDYeuhJits4Imd9AV9Mh4E=";
          };

          # Daemon: cycle saved output/input device slots and toggle
          # focused-app mute via DMS IPC.
          audioSlots.src = pkgs.fetchFromGitHub {
            owner = "lpv11";
            repo = "dms-audio-slots";
            rev = "f460499b996bfc8fadd55ed65e44e1338afda06e";
            hash = "sha256-jFx62uGv57ucYJdLw2Vga0/mNhd/b7NgXBD2TAS3Dps=";
          };

          # Widget: quickly toggle between different audio sinks.
          audioSwitcher.src = pkgs.fetchFromGitHub {
            owner = "CD-Z";
            repo = "dms-plugins";
            rev = "c510ed4f29c5128512130051100e5c86464c95a6";
            hash = "sha256-jGsB+oT9Jpm2lycuFFLp0etqUUoG3GJRJOqZqZUSk6w=";
          };

          # Widget: standalone per-app volume mixer in the bar.
          volumeMixer.src = pkgs.fetchFromGitHub {
            owner = "cwelsys";
            repo = "dms-volume-mixer";
            rev = "3996bdfbc11cb7458d9d23e45a69ec2374cf8601";
            hash = "sha256-yBgHyTvWz381UJq7wuHdaxYjn7DQ2f40qwj3kxUt9Ko=";
          };
        };
      };
  };
}
