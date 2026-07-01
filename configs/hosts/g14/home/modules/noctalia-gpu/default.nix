{lib, ...}: let
  windowManagers = [
    "hyprland"
    "sway"
    "mango"
  ];

  pluginName = "g14-gpu";
  pluginId = "edward/${pluginName}";
  pluginSource = ./g14-gpu;
  pluginConfig = ''
    [plugins]
    enabled = ["${pluginId}"]
  '';
in {
  edward.noctalia.extraConfigText = lib.genAttrs windowManagers (_: pluginConfig);

  xdg.dataFile = lib.mkMerge (
    map (wm: {
      "noctalia-${wm}/noctalia/plugins/${pluginName}".source = pluginSource;
    })
    windowManagers
  );
}
