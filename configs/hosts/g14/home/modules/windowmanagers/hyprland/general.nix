{lib, ...}: {
  wayland.windowManager.hyprland.settings = {
    monitor = [
      {
        output = "eDP-1";
        mode = "2560x1600@60";
        position = "0x0";
        scale = 1.6;
      }
      {
        output = "eDP-2";
        mode = "2560x1600@60";
        position = "0x0";
        scale = 1.6;
      }
      {
        output = "HDMI-A-1";
        mode = "preferred";
        position = "auto-right";
        scale = 2;
      }
      {
        output = "HDMI-A-2";
        mode = "preferred";
        position = "auto-right";
        scale = 2;
      }
    ];

    # Override `true` from the shared configuration so sensitivity works.
    config.input.force_no_accel = lib.mkForce false;

    device = {
      name = "asue120a:00-04f3:319b-touchpad";
      sensitivity = 0.6;
    };
  };
}
