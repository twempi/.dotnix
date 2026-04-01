{pkgs, ...}: {
  programs = {
    hyprland = {
      enable = true;
      withUWSM = false;
      portalPackage = pkgs.xdg-desktop-portal-hyprland;
    };
  };

  xdg.portal.config.hyprland.default = ["hyprland" "gtk"];
}
