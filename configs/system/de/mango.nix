{inputs, ...}: {
  imports = [
    inputs.mangowm.nixosModules.mango
  ];
  programs = {
    mango = {
      enable = true;
    };
  };

  # xdg.portal.config.hyprland.default = ["hyprland" "gtk"];
}
