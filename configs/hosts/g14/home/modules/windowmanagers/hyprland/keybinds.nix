{
  config,
  lib,
  ...
}: let
  toLua = lib.generators.toLua {};
  sessionPanel = "${config.edward.noctalia.commands.hyprland} msg panel-toggle session";
in {
  wayland.windowManager.hyprland.settings.bind = [
    {
      _args = [
        (lib.generators.mkLuaInline ''mod .. " + XF86Launch1"'')
        (lib.generators.mkLuaInline "hl.dsp.exec_cmd(${toLua sessionPanel})")
      ];
    }
  ];
}
