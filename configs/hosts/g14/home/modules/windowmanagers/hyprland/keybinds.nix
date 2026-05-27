{lib, ...}: {
  wayland.windowManager.hyprland.settings.bind = [
    {
      _args = [
        (lib.generators.mkLuaInline ''mod .. " + XF86Launch1"'')
        (lib.generators.mkLuaInline ''hl.dsp.exec_cmd("uwsm app -- qs-gpu")'')
      ];
    }
  ];
}
