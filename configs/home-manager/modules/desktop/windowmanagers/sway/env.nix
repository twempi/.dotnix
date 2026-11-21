{
  flake.modules.homeManager.sway = {
    home.sessionVariables = {
      NIXOS_OZONE_WL = 1;
      MOZ_ENABLE_WAYLAND = 1;
      # XDG_CURRENT_DESKTOP = "sway";
      # XDG_SESSION_DESKTOP = "sway";
      XDG_SESSION_TYPE = "wayland";
      GDK_BACKEND = "wayland,x11";
      QT_QPA_PLATFORM = "wayland;xcb";
    };
  };
}
