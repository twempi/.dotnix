{
  pkgs,
  inputs,
  ...
}: let
  hyprPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
  hyprPortal = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
in {
  programs = {
    hyprland = {
      enable = true;
      withUWSM = true;
      xwayland.enable = true;
      package = hyprPackage;
      portalPackage = hyprPortal;
    };
  };

  xdg.portal.config.hyprland.default = ["hyprland" "gtk"];
}
