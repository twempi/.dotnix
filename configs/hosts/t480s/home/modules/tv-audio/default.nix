{pkgs, ...}: let
  tvAudio = pkgs.writeShellApplication {
    name = "t480s-tv-audio";
    runtimeInputs = with pkgs; [
      coreutils
      gawk
      wireplumber
    ];
    text = ''
      for _ in $(seq 1 20); do
        sink="$(
          { wpctl status 2>/dev/null || true; } | awk '
            /Sinks:/ { in_sinks = 1; next }
            /Sources:/ { in_sinks = 0 }
            in_sinks && /(HDMI|DisplayPort|LG|Digital Stereo)/ {
              if (match($0, /([0-9]+)\./, id)) {
                print id[1]
                exit
              }
            }
          '
        )"

        if [ -n "$sink" ]; then
          wpctl set-default "$sink"
          exit 0
        fi

        sleep 1
      done

      exit 0
    '';
  };
in {
  home.packages = [tvAudio];

  systemd.user.services.t480s-tv-audio = {
    Unit = {
      Description = "Prefer HDMI audio for the t480s TV session";
      After = [
        "graphical-session.target"
        "pipewire.service"
        "wireplumber.service"
      ];
      Wants = ["wireplumber.service"];
    };

    Service = {
      Type = "oneshot";
      ExecStart = "${tvAudio}/bin/t480s-tv-audio";
    };

    Install.WantedBy = ["graphical-session.target"];
  };
}
