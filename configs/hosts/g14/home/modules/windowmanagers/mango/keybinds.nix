{config, ...}: let
  gpuSwitcher = "${config.edward.noctalia.commands.mango} msg panel-toggle edward/g14-gpu:switcher";
in {
  wayland.windowManager.mango.settings.bind = [
    "SUPER,XF86Launch1,spawn,${gpuSwitcher}"
  ];
}
