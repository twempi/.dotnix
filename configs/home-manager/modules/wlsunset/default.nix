{pkgs, ...}: let
  syncScript = pkgs.writeShellScript "wlsunset-sync" ''
    set -eu

    hour="$(${pkgs.coreutils}/bin/date +%H)"

    if [ "$hour" -ge 20 ] || [ "$hour" -lt 8 ]; then
      ${pkgs.systemd}/bin/systemctl --user start wlsunset.service
    else
      ${pkgs.systemd}/bin/systemctl --user stop wlsunset.service
    fi
  '';
in {
  home.packages = [pkgs.wlsunset];

  systemd.user.services.wlsunset = {
    Unit = {
      Description = "Wayland blue light filter";
      After = ["graphical-session.target"];
      PartOf = ["graphical-session.target"];
    };

    Service = {
      Type = "simple";
      ExecStart = "${pkgs.wlsunset}/bin/wlsunset -T 4001 -t 4001";
      Restart = "on-failure";
      RestartSec = 2;
    };
  };

  systemd.user.services.wlsunset-sync = {
    Unit = {
      Description = "Start or stop wlsunset based on time";
      After = ["graphical-session.target"];
    };

    Service = {
      Type = "oneshot";
      ExecStart = syncScript;
    };

    Install = {
      WantedBy = ["default.target"];
    };
  };

  systemd.user.timers.wlsunset-sync = {
    Unit = {
      Description = "Switch wlsunset at 08:00 and 20:00";
    };

    Timer = {
      OnCalendar = ["*-*-* 08:00:00" "*-*-* 20:00:00"];
      Unit = "wlsunset-sync.service";
      Persistent = true;
    };

    Install = {
      WantedBy = ["timers.target"];
    };
  };
}
