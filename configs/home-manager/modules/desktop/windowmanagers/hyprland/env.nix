{config, ...}: {
  xdg.configFile."uwsm/env".source = "${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh";

  wayland.windowManager.hyprland.settings = {
    xwayland = {
      "force_zero_scaling" = true;
      env = [
        "GDK_SCALE,1"
        "XCURSOR_SIZE,24"
      ];
    };
  };
}
