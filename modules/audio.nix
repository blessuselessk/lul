{
  den.aspects.audio.nixos =
    { pkgs, ... }:
    {
      services.pulseaudio.enable = false;
      security.rtkit.enable = true;
      services.pipewire = {
        enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;

        extraConfig.pipewire = {
          # Stage 1: WebRTC echo cancellation — removes speaker output bleed
          # from the mic signal before anything else sees it. Creates two
          # virtual nodes: echo-cancel-source (clean mic) and
          # echo-cancel-sink (loopback for the AEC reference signal).
          "11-echo-cancel" = {
            "context.modules" = [
              {
                name = "libpipewire-module-echo-cancel";
                args = {
                  "library.name" = "aec/libspa-aec-webrtc";
                  "aec.args" = {
                    "webrtc.gain_control" = true;
                    "webrtc.extended_filter" = true;
                    "webrtc.delay_agnostic" = true;
                  };
                  "source.props"."node.name" = "echo-cancel-source";
                  "source.props"."node.description" = "Echo Cancelled Mic";
                  "sink.props"."node.name" = "echo-cancel-sink";
                  "sink.props"."node.description" = "Echo Cancellation Reference";
                };
              }
            ];
          };

          # Stage 2: RNNoise neural noise suppression — takes echo-cancel-source
          # as input and produces rnnoise-source, a virtual mic with both echo
          # and ambient noise removed. This is what voxtype and other apps
          # should record from.
          "12-rnnoise-source" = {
            "context.modules" = [
              {
                name = "libpipewire-module-filter-chain";
                args = {
                  "node.name" = "rnnoise-source";
                  "node.description" = "Noise Cancelled Mic";
                  "media.name" = "Noise Cancellation";
                  "filter.graph".nodes = [
                    {
                      type = "ladspa";
                      name = "rnnoise";
                      plugin = "${pkgs.rnnoise-plugin}/lib/ladspa/librnnoise_ladspa.so";
                      label = "noise_suppressor_mono";
                      control."VAD Threshold (%)" = 50.0;
                      control."VAD Grace Period (ms)" = 200;
                      control."Retroactive VAD Grace (ms)" = 0;
                    }
                  ];
                  "capture.props" = {
                    "node.name" = "capture.rnnoise-source";
                    "audio.position" = [ "MONO" ];
                    # Pull from the echo-cancelled source, not the raw mic.
                    "target.object" = "echo-cancel-source";
                  };
                  "playback.props" = {
                    "node.name" = "rnnoise-source";
                    "media.class" = "Audio/Source";
                    "audio.position" = [ "MONO" ];
                  };
                };
              }
            ];
          };
        };
      };

      # alsa-utils: amixer/aplay/speaker-test for audio debugging
      environment.systemPackages = [ pkgs.alsa-utils pkgs.rnnoise-plugin ];
    };
}
