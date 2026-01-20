{
  pkgs,
  config,
  ...
}: {
  programs.niri.settings = {
    hotkey-overlay.skip-at-startup = true;
    prefer-no-csd = true;

    screenshot-path = "~/Pictures/Screenshots/Screenshot-%Y-%m-%d_%H-%M-%S.png";

    outputs = {
      "*" = {
        mode = {
          height = 1440;
          width = 2560;
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
          height = 1080;
          width = 1920;
          refresh = 60.0;
        };

        position = {
          x = 0;
          y = -1080;
        };
        scale = 1.0;
      };

      "eDP-1" = {
        mode = {
          height = 1080;
          width = 1920;
          refresh = 60.031;
        };
        position = {
          x = 0;
          y = 0;
        };
        scale = 1.0;
      };
    };

    spawn-at-startup = [
      {argv = ["swww-daemon"];}
      {
        argv = [
          "${pkgs.waybar}/bin/waybar"
          "-c"
          "${config.home.homeDirectory}/.config/waybar/niri.jsonc"
          "-s"
          "${config.home.homeDirectory}/.config/waybar/niri.css"
        ];
      }

      {
        argv = [
          "${pkgs.openrgb}/bin/openrgb"
          "--profile"
          "${config.home.homeDirectory}/.config/OpenRGB/black.orp"
        ];
      }

      {
        argv = [
          "${pkgs.bash}/bin/bash"
          "-lc"
          "sleep 4 && ${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 1"
        ];
      }
      {
        argv = [
          "${pkgs.bash}/bin/bash"
          "-lc"
          "sleep 5 && ${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 1"
        ];
      }

      {argv = ["${pkgs.cliphist}/bin/cliphist" "wipe"];}
      {
        argv = [
          "${pkgs.wl-clipboard}/bin/wl-paste"
          "--type"
          "text"
          "--watch"
          "${pkgs.cliphist}/bin/cliphist"
          "store"
        ];
      }
    ];

    layout = {
      gaps = 5;

      default-column-width = {
        proportion = 0.5;
      };

      border = {
        enable = true;
        width = 2.0;
      };

      shadow = {
        enable = true;
        softness = 30;
        spread = 5;
        offset = {
          x = 0;
          y = 5;
        };
        color = "rgba(26, 26, 26, 0.93)";
      };
    };

    input = {
      focus-follows-mouse.enable = true;

      keyboard.xkb.layout = "us";

      keyboard.numlock = true;

      mouse = {
        "accel-profile" = "flat";
        "accel-speed" = 0.0;
      };

      touchpad = {
        "natural-scroll" = false;
        "scroll-factor" = 1.0;
      };
    };
  };
}
