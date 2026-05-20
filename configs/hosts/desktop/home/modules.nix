{
  imports = [
    {
      wayland.windowManager.hyprland.settings.monitor = [
        "DP-3,2560x1440@180,0x0,1"
        "HDMI-A-2,1920x1080@70,2560x0,1"
      ];
    }
    ./modules/de/sway
    ./modules/de/mango
    ./modules/fish
  ];
}
