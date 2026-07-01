{config, ...}: let
  sessionPanel = "${config.edward.noctalia.commands.mango} msg panel-toggle session";
  gpuSwitcherPanel = "${config.edward.noctalia.commands.mango} msg panel-toggle edward/gpu-switcher:main";
in {
  wayland.windowManager.mango.settings.bind = [
    "SUPER,XF86Launch1,spawn,${sessionPanel}"
    "NONE,XF86Launch4,spawn,${gpuSwitcherPanel}"
  ];
}
