{pkgs, ...}: {
  programs = {
    hyprland = {
      enable = true;
      withUWSM = true;
      xwayland.enable = true;
      portalPackage = pkgs.xdg-desktop-portal-hyprland;
    };
  };

  xdg.portal.config.hyprland.default = ["hyprland" "gtk"];
}
