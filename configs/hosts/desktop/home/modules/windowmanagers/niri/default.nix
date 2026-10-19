{
  flake.modules.homeManager.desktop-niri = {pkgs, ...}: {
    programs.niri.settings = {
      outputs = {
        "DP-4" = {
          mode = {
            width = 2560;
            height = 1440;
            refresh = 180.002;
          };
          position = {
            x = 0;
            y = 0;
          };
          scale = 1.0;
        };

        "HDMI-A-2" = {
          mode = {
            width = 1920;
            height = 1080;
            refresh = 60.00;
          };
          position = {
            x = 02560;
            y = 0;
          };
          scale = 1.0;
        };
      };

      spawn-at-startup = [
        {command = ["${pkgs.openrgb}/bin/openrgb" "--profile" "/home/edward/.config/OpenRGB/black.orp"];}
      ];

      binds."Ctrl+backslash".action.spawn = ["${pkgs.handy}/bin/handy" "--toggle-transcription"];
    };
  };
}
