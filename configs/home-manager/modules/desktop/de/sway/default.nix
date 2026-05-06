{pkgs, ...}: {
  imports = [
    ./general.nix
    ./keybinds.nix
    ./windowrules.nix
  ];

  stylix.targets.sway.enable = true;

  # sway
  wayland.windowManager.sway = {
    systemd.enable = true;
    enable = true;
    # package = pkgs.swayfx;
    xwayland = true;
    checkConfig = false;
    extraOptions = ["--unsupported-gpu"];
  };

  home.sessionVariables = {
    NIXOS_OZONE_WL = 1;
    MOZ_ENABLE_WAYLAND = 1;
    # XDG_CURRENT_DESKTOP = "sway";
    # XDG_SESSION_DESKTOP = "sway";
    XDG_SESSION_TYPE = "wayland";
    GDK_BACKEND = "wayland,x11";
    QT_QPA_PLATFORM = "wayland;xcb";
  };

  xdg.portal = {
    enable = true;
    xdgOpenUsePortal = true;
    config = {
      sway.default = ["wlr" "gtk"];
    };
    extraPortals = with pkgs; [
      xdg-desktop-portal-wlr
      xdg-desktop-portal-gtk
    ];
  };
}
