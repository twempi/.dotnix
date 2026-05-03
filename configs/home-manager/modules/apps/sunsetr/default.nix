{pkgs, ...}: {
  home.packages = [
    pkgs.sunsetr
  ];

  xdg.configFile."sunsetr/sunsetr.toml".text = ''
    backend = "wayland"
    transition_mode = "finish_by"

    # Fully ON at 8:00 PM
    sunset = "20:00:00"

    # Fully OFF at 7:00 AM
    sunrise = "07:00:00"

    # Smallest supported fade window
    transition_duration = 5

    # Day = neutral / effectively off
    day_temp = 6500
    day_gamma = 100

    # Night = warm / on
    night_temp = 3300
    night_gamma = 90

    smoothing = true
    startup_duration = 0.5
    shutdown_duration = 0.5
  '';

  systemd.user.services.sunsetr = {
    Unit = {
      Description = "sunsetr blue-light filter";
    };

    Service = {
      ExecStart = "${pkgs.sunsetr}/bin/sunsetr";
      Restart = "on-failure";
    };

    Install = {
      WantedBy = ["default.target"];
    };
  };
}
