{pkgs, ...}: {
  home.packages = [
    pkgs.sunsetr
  ];

  xdg.configFile."sunsetr/sunsetr.toml".text = ''
    backend = "wayland"
    transition_mode = "finish_by"

    sunset = "20:00:00"
    sunrise = "07:00:00"

    transition_duration = 5

    day_temp = 6500
    day_gamma = 100

    night_temp = 3300
    night_gamma = 90

    smoothing = true
    startup_duration = 0.5
    shutdown_duration = 0.5
  '';

  systemd.user.startServices = "sd-switch";

  systemd.user.services.sunsetr = {
    Unit = {
      Description = "sunsetr blue-light filter";
      Documentation = "https://github.com/psi4j/sunsetr";

      PartOf = ["graphical-session.target"];
      Requires = ["graphical-session.target"];
      After = ["graphical-session.target"];

      ConditionEnvironment = ["WAYLAND_DISPLAY"];
    };

    Service = {
      Type = "simple";
      ExecStart = "${pkgs.sunsetr}/bin/sunsetr";
      Restart = "on-failure";
      RestartSec = "30s";
      Slice = "background.slice";
    };

    Install = {
      WantedBy = ["graphical-session.target"];
    };
  };
}
