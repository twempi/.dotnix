{
  flake.modules.homeManager.hyprland = {config, ...}: {
    stylix.targets.hyprland.enable = true;

    # Clipboard history for amane-clipboard.
    services.cliphist = {
      enable = true;
      systemdTargets = ["wayland-session@hyprland.desktop.target"];
    };

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
