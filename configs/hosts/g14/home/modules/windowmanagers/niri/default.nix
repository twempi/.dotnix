{
  flake.modules.homeManager.g14-niri = {
    config,
    pkgs,
    ...
  }: {
    programs.niri.settings = {
      outputs = {
        "eDP-1" = {
          mode = {
            width = 2560;
            height = 1600;
            refresh = 60.0;
          };
          position = {
            x = 0;
            y = 0;
          };
          scale = 1.5;
        };
        "eDP-2" = {
          mode = {
            width = 2560;
            height = 1600;
            refresh = 60.0;
          };
          position = {
            x = 0;
            y = 0;
          };
          scale = 1.5;
        };
        "HDMI-A-1" = {
          position = {
            x = 1707;
            y = 0;
          };
          scale = 2.0;
        };
        "HDMI-A-2" = {
          position = {
            x = 1707;
            y = 0;
          };
          scale = 2.0;
        };
      };

      binds = {
        "XF86KbdBrightnessUp".action.spawn = ["${pkgs.asusctl}/bin/asusctl" "leds" "next"];
        "XF86KbdBrightnessDown".action.spawn = ["${pkgs.asusctl}/bin/asusctl" "leds" "prev"];
        "Mod+XF86Launch1".action.spawn = [config.edward.noctalia.commands.niri "msg" "panel-toggle" "edward/g14-gpu:switcher"];
      };
    };
  };
}
