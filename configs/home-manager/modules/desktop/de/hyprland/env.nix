{
  xdg.configFile."uwsm/env".text = ''
    export NIXOS_OZONE_WL=1
    export MOZ_ENABLE_WAYLAND=1
    export GDK_BACKEND=wayland,x11
    export QT_QPA_PLATFORM='wayland;xcb'
    export XCURSOR_SIZE=24
  '';

  xdg.configFile."uwsm/env-hyprland".text = ''
    export WLR_DRM_NO_ATOMIC=1
    export WLR_RENDERER_ALLOW_SOFTWARE=1
    export WLR_USE_LIBINPUT=1
    export WLR_NO_HARDWARE_CURSORS=1
  '';

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
