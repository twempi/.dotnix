{
  imports = [
    {
      wayland.windowManager.hyprland.settings.monitor = [
        "eDP-1,2560x1600@120,0x0,1.5"
      ];
    }
    ./modules/de/sway
    ./modules/de/mango
    ./modules/fish
    ./modules/fastfetch
  ];
}
