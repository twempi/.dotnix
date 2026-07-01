{
  config,
  lib,
  ...
}: let
  toLua = lib.generators.toLua {};
  sessionPanel = "${config.edward.noctalia.commands.hyprland} msg panel-toggle session";
  gpuSwitcherPanel = "${config.edward.noctalia.commands.hyprland} msg panel-toggle edward/gpu-switcher:main";
in {
  wayland.windowManager.hyprland.settings.bind = [
    {
      _args = [
        (lib.generators.mkLuaInline ''mod .. " + XF86Launch1"'')
        (lib.generators.mkLuaInline "hl.dsp.exec_cmd(${toLua sessionPanel})")
      ];
    }
    {
      _args = [
        "XF86Launch4"
        (lib.generators.mkLuaInline "hl.dsp.exec_cmd(${toLua gpuSwitcherPanel})")
      ];
    }
  ];
}
