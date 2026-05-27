{config, ...}: {
  xdg.configFile."uwsm/env".source = "${config.home.sessionVariablesPackage}/etc/profile.d/hm-session-vars.sh";

  wayland.windowManager.hyprland.settings = {
    config.xwayland."force_zero_scaling" = true;

    env = [
      {
        _args = [
          "GDK_SCALE"
          "1"
        ];
      }
      {
        _args = [
          "XCURSOR_SIZE"
          "24"
        ];
      }
    ];
  };
}
