{
  config,
  lib,
  ...
}: let
  toLua = lib.generators.toLua {};
  gpuSwitcher = "${config.edward.noctalia.commands.hyprland} msg panel-toggle launcher /gpu";
in {
  wayland.windowManager.hyprland.settings.bind = [
    {
      _args = [
        (lib.generators.mkLuaInline ''mod .. " + XF86Launch1"'')
        (lib.generators.mkLuaInline "hl.dsp.exec_cmd(${toLua gpuSwitcher})")
      ];
    }
  ];
}
