{...}: {
  wayland.windowManager.hyprland.settings.bind = [
    "$mod, XF86Launch1, exec, uwsm app -- qs-gpu"
  ];
}
