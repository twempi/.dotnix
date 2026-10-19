{
  flake.modules.homeManager.desktop-sway = {
    wayland.windowManager.sway.config = {
      output = {
        "DP-1" = {
          enable = "";
          mode = "2560x1440@180.002Hz";
          power = "on";
          pos = "0 0";
          scale = "1.0";
        };

        "HDMI-A-1" = {
          enable = "";
          mode = "1920x1080@60.000Hz";
          power = "on";
          pos = "2560 0";
          scale = "1.0";
        };
      };

      workspaceOutputAssign = [
        {
          workspace = "1";
          output = "DP-1";
        }
        {
          workspace = "2";
          output = "HDMI-A-1";
        }
      ];
    };
  };
}
