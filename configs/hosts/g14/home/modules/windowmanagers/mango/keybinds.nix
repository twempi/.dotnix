{config, ...}: let
  sessionPanel = "${config.edward.noctalia.commands.mango} msg panel-toggle session";
in {
  wayland.windowManager.mango.settings.bind = [
    "SUPER,XF86Launch1,spawn,${sessionPanel}"
  ];
}
