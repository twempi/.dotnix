{pkgs, ...}: {
  wayland.windowManager.sway = {
    output = {
      "*" = {
        mode = "2560x1440@180.002Hz";
        pos = "0 0";
        scale = "1.5";
      };
    };
  };
}
