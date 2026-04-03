{pkgs, ...}: {
  wayland.windowManager.sway = {
    output = {
      "eDP-1" = {
        mode = "2650x1600@120.000Hz";
        pos = "0 0";
        scale = "1.5";
      };
    };
  };
}
