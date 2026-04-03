{pkgs, ...}: {
  wayland.windowManager.sway.config = {
      output = {
        "*" = {
          mode = "2650x1600@120.000Hz";
          pos = "0 0";
          scale = "1.5";
        };
      };
    };
}
