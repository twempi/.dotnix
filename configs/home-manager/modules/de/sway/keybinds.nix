{
  pkgs,
  ...
}: {
  wayland.windowManager.sway.config = {
    modifier = "Mod4";
    terminal = "${pkgs.foot}/bin/foot";
    menu = "${pkgs.rofi}/bin/rofi -show drun";

    floating.modifier = "Mod4";

    # mousebindings = {
    #   "Mod4+button1" = "move";
    #   "Mod4+button3" = "resize";
    # };
    #
    keybindings = {
      # Basic
      "Mod4+Q" = "kill";
      "Mod4+V" = "floating toggle";
      "Mod4+F" = "fullscreen toggle";

      # Apps
      "Mod4+Return" = "exec ${pkgs.foot}/bin/foot";
      "Mod4+B" = "exec ${pkgs.brave}/bin/brave";
      "Mod4+E" = "exec ${pkgs.foot}/bin/foot -e ${pkgs.yazi}/bin/yazi";
      "Mod4+Shift+E" = "exec ${pkgs.nautilus}/bin/nautilus";
      "Mod4+M" = "exec spotify";
      "Mod4+O" = "exec ${pkgs.obsidian}/bin/obsidian";
      "Mod4+N" = "exec ${pkgs.foot}/bin/foot -e nvim";
      "Mod4+Shift+B" = "exec ${pkgs.foot}/bin/foot -e bluetui";
      "Mod4+Shift+N" = "exec ${pkgs.swaynotificationcenter}/bin/swaync-client -t -sw";
      "Mod4+Escape" = "exec rofi-power";
      "Mod4+Shift+W" = "exec rofi-wallpaper";
      "Mod4+Shift+R" = "exec ${./reload.sh}";

      # Screenshots
      "Mod4+Shift+S" = "exec ${./screenshot.sh}";
      "Print" = "exec ${pkgs.grim}/bin/grim - | ${pkgs.wl-clipboard}/bin/wl-copy && ${pkgs.wl-clipboard}/bin/wl-paste > ~/Pictures/Screenshots/Screenshot-$(date +%F_%T).png";

      # Rofi things
      "Mod4+Space" = "exec ${pkgs.rofi}/bin/rofi -show drun";
      "Mod4+U" = "exec ${pkgs.bemoji}/bin/bemoji";
      "Mod4+Y" = "exec cliphist list | $menu -dmenu | cliphist decode | wl-copy";

      # Move focus
      "Mod4+H" = "focus left";
      "Mod4+J" = "focus down";
      "Mod4+K" = "focus up";
      "Mod4+L" = "focus right";

      # Move containters
      "Mod4+Ctrl+H" = "move left 50px";
      "Mod4+Ctrl+J" = "move down 50px";
      "Mod4+Ctrl+K" = "move up 50px";
      "Mod4+Ctrl+L" = "move right 50px";

      # Workspaces
      "Mod4+1" = "workspace 1";
      "Mod4+2" = "workspace 2";
      "Mod4+3" = "workspace 3";
      "Mod4+4" = "workspace 4";
      "Mod4+5" = "workspace 5";
      "Mod4+6" = "workspace 6";
      "Mod4+7" = "workspace 7";
      "Mod4+8" = "workspace 8";
      "Mod4+9" = "workspace 9";
      "Mod4+0" = "workspace 10";

      # Move container to workspace
      "Mod4+Shift+1" = "move container to workspace 1";
      "Mod4+Shift+2" = "move container to workspace 2";
      "Mod4+Shift+3" = "move container to workspace 3";
      "Mod4+Shift+4" = "move container to workspace 4";
      "Mod4+Shift+5" = "move container to workspace 5";
      "Mod4+Shift+6" = "move container to workspace 6";
      "Mod4+Shift+7" = "move container to workspace 7";
      "Mod4+Shift+8" = "move container to workspace 8";
      "Mod4+Shift+9" = "move container to workspace 9";
      "Mod4+Shift+0" = "move container to workspace 10";

      # Multimedia keys
      "XF86AudioLowerVolume" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
      "XF86AudioRaiseVolume" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+";
      "XF86AudioMute" = "exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
      "XF86AudioMicMute" = "exec wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
      "XF86MonBrightnessUp" = "exec brightnessctl set 5%+";
      "XF86MonBrightnessDown" = "exec brightnessctl set 5%-";

      # Media keys
      "XF86AudioNext" = "exec playerctl next";
      "XF86AudioPause" = "exec playerctl play-pause";
      "XF86AudioPlay" = "exec playerctl play-pause";
      "XF86AudioPrev" = "exec playerctl previous";
    };
  };
}
