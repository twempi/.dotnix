{
  dotnix.hyprland.autostart = {
    openrgb = false;
    obsidian = false;
    spotify = true;
  };

  wayland.windowManager.hyprland.settings = {
    monitor = [
      {
        output = "HDMI-A-1";
        mode = "preferred";
        position = "0x0";
        scale = 1;
      }
      {
        output = "eDP-1";
        mode = "preferred";
        position = "auto-right";
        scale = 1;
      }
    ];

    workspace_rule = [
      {
        workspace = "1";
        monitor = "HDMI-A-1";
        default = true;
      }
      {
        workspace = "9";
        monitor = "HDMI-A-1";
        default = true;
      }
    ];
  };
}
