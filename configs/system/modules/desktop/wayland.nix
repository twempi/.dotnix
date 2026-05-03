{pkgs, ...}: {
  programs.xwayland.enable = true;

  environment.sessionVariables = {
    GSK_RENDERER = "ngl";
    # GTK_USE_PORTAL = "0";
    GDK_BACKEND = "wayland,x11";
    # SDL_VIDEODRIVER = "wayland";
    CLUTTER_BACKEND = "wayland";
    QT_QPA_PLATFORMTHEME = "qt5ct";
    ELECTRON_OZONE_PLATFORM_HINT = "wayland";
    # XDG_SESSION_TYPE = "wayland";
    NIXOS_OZONE_WL = "1";
  };

  security.pam.services.ly.enableGnomeKeyring = true;

  xdg = {
    portal = {
      enable = true;
      xdgOpenUsePortal = true;
      config.common.default = ["gtk"];
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
        xdg-desktop-portal-hyprland
        xdg-desktop-portal-wlr
        xdg-desktop-portal-gnome
      ];
    };
  };
}
