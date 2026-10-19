{
  flake.modules.homeManager.hyprland = {config, ...}: {
    stylix.targets.hyprland.enable = true;

    # hyprland
    wayland.windowManager.hyprland = {
      enable = true;
      systemd.enable = false;
      configType = "lua";
      package = null;
      portalPackage = null;
    };

    home.sessionVariables.HYPRLAND_CONFIG = "${config.xdg.configHome}/hypr/hyprland.lua";
  };
}
