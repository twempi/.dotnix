{
  pkgs,
  inputs,
  ...
}: let
  system = pkgs.stdenv.hostPlatform.system;

  hyprPackage = inputs.hyprland.packages.${system}.hyprland;
  hyprPortal =
    inputs.hyprland.packages.${system}.xdg-desktop-portal-hyprland;
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
