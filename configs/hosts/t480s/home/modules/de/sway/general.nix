{pkgs, ...}: {
  wayland.windowManager.sway = {
    output = {
      "eDP-1" = {
        mode = "1920x1080@60.031Hz";
        pos = "0 0";
        scale = "1.0";
      };
    };
  };
}
