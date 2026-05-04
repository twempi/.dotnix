{pkgs, ...}: {
  wayland.windowManager.hyprland.settings = {
    # Apps
    # "$wallpaper" = "${pkgs.waypaper}/bin/waypaper";
    "$menu" = "${pkgs.rofi}/bin/rofi";
    "$colorPicker" = "${pkgs.hyprpicker}/bin/hyprpicker -a";
    "$noti-center" = "${pkgs.swaynotificationcenter}/bin/swaync-client -t -sw";

    # "$terminal" = "${pkgs.ghostty}/bin/ghostty";
    "$terminal" = "${pkgs.kitty}/bin/kitty";
    # "$browser" = "${pkgs.brave}/bin/brave";
    # "$browser" = "zen-beta";
    "$browser" = "helium";
    "$explorer1" = "$terminal -e ${pkgs.yazi}/bin/yazi";
    "$explorer2" = "${pkgs.nautilus}/bin/nautilus";
    "$notes" = "${pkgs.obsidian}/bin/obsidian";
    "$emoji" = "${pkgs.bemoji}/bin/bemoji";
    "$bluetooth" = "$terminal -e ${pkgs.bluetui}/bin/bluetui";
    "$editor" = "$terminal -e nvim";

    "$mod" = "SUPER";
    "$qs" = "bash ~/.config/hypr/scripts/qs_manager.sh";

    bind =
      [
        # Basic
        "$mod, Q, killactive,"
        "$mod SHIFT, Q, exec, hyprctl activewindow | grep pid | tr -d 'pid:'| xargs kill,"
        "$mod, V, togglefloating,"
        "$mod, F, fullscreen, 1"
        "$mod SHIFT, F, fullscreen, 0"

        "$mod, return, exec, $terminal"
        "$mod, B, exec, $browser"
        "$mod, E, exec, $explorer1"
        "$mod SHIFT, E, exec, $explorer2"
        "$mod, M, exec, spotify"
        "$mod, O, exec, $notes"
        "$mod, N, exec, $editor"
        "$mod SHIFT, B, exec, $bluetooth"
        "$mod SHIFT, N, exec, $noti-center"
        "$mod, ESCAPE, exec, rofi-power"

        "$mod, Z, exec, $colorPicker"
        "$mod SHIFT, W, exec, rofi-wallpaper"
        "$mod SHIFT, R, exec, ${./reload.sh}"

        # Screenshot(grim + slurp)
        "$mod SHIFT, S, exec, ${./screenshot.sh}"
        ", Print, exec, ${pkgs.grim}/bin/grim - | ${pkgs.wl-clipboard}/bin/wl-copy && ${pkgs.wl-clipboard}/bin/wl-paste > ~/Pictures/Screenshots/Screenshot-$(date +%F_%T).png"

        # Rofi thing
        "$mod, Space, exec, $menu -show drun"
        "$mod, U, exec, $emoji"
        "$mod, Y, exec, cliphist list | $menu -dmenu | cliphist decode | wl-copy"

        # Move focus with $mod + HJKL(Vim keys)
        "$mod, H, movefocus, l"
        "$mod, L, movefocus, r"
        "$mod, J, movefocus, d"
        "$mod, K, movefocus, u"

        # Move windows with $mod + CTRL + HJKL(Vim keys)
        "$mod CTRL, H, movewindow, l"
        "$mod CTRL, L, movewindow, r"
        "$mod CTRL, J, movewindow, d"
        "$mod CTRL, K, movewindow, u"

        # Workspaces
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod, 6, workspace, 6"
        "$mod, 7, workspace, 7"
        "$mod, 9, workspace, 9"
        "$mod, 9, workspace, 9"
        "$mod, 0, workspace, 10"

        # Move active window to workspace #
        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"
        "$mod SHIFT, 6, movetoworkspace, 6"
        "$mod SHIFT, 7, movetoworkspace, 7"
        "$mod SHIFT, 8, movetoworkspace, 8"
        "$mod SHIFT, 9, movetoworkspace, 9"
        "$mod SHIFT, 0, movetoworkspace, 10"

        # QuickShell toggles (merged from ilyamiro, remapped to avoid conflicts)
        "$mod ALT, M, exec, $qs toggle monitors"
        "$mod ALT, S, exec, $qs toggle stewart"
        "$mod ALT, Q, exec, $qs toggle music"
        "$mod ALT, B, exec, $qs toggle battery"
        "$mod ALT, W, exec, $qs toggle wallpaper"
        "$mod ALT, C, exec, $qs toggle calendar"
        "$mod ALT, N, exec, $qs toggle network"
        "$mod ALT, T, exec, $qs toggle focustime"
        "$mod ALT, V, exec, $qs toggle volume"
        "$mod ALT, G, exec, $qs toggle guide"
      ]
      ++ (
        # workspaces 1-9
        builtins.concatLists (builtins.genList (
            i: let
              ws = i + 1;
            in [
              "$mod, code:1${toString i}, workspace, ${toString ws}"
              "$mod SHIFT, code:1${toString i}, movetoworkspacesilent, ${toString ws}"
            ]
          )
          9)
      );

    bindm = [
      # Move windows with mouse
      "$mod, mouse:272, movewindow"
      # Resize windows with mouse
      "$mod, mouse:273, resizewindow"
    ];

    binde = [
      # Resize windows with $mod + Shift + HJKL(vim keys)
      "$mod SHIFT, H, resizeactive,-50 0"
      "$mod SHIFT, L, resizeactive,50 0"
      "$mod SHIFT, J, resizeactive,0 -50"
      "$mod SHIFT, K, resizeactive,0 50"
    ];

    bindel = [
      # Laptop multimedia keys for volume and LCD brightness
      ",XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
      ",XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
      ",XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
      ",XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
      ",XF86MonBrightnessUp, exec, brightnessctl set 5%+"
      ",XF86MonBrightnessDown, exec, brightnessctl set 5%-"
    ];

    bindl = [
      # Requires playerctl
      ",XF86AudioNext, exec, playerctl next"
      ",XF86AudioPause, exec, playerctl play-pause"
      ",XF86AudioPlay, exec, playerctl play-pause"
      ",XF86AudioPrev, exec, playerctl previous"
    ];
  };
}
