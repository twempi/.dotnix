{
  config,
  pkgs,
  lib,
  ...
}: let
  noctalia = "${config.edward.noctalia.commands.sway} msg";
in {
  wayland.windowManager.sway.config = {
    modifier = "Mod4";
    terminal = "${pkgs.foot}/bin/foot";

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

      # Force kill
      "Mod4+Shift+Q" = "exec ${pkgs.sway}/bin/swaymsg -t get_tree | ${pkgs.jq}/bin/jq -r '.. | select(.focused? == true) | .pid // empty' | xargs -r kill";

      # Apps
      "Mod4+Return" = "exec ${pkgs.foot}/bin/foot";
      # "Mod4+B" = "exec ${pkgs.brave}/bin/brave";
      # "Mod4+B" = "exec zen-beta";
      "Mod4+B" = "exec helium";
      "Mod4+E" = "exec ${pkgs.foot}/bin/foot -e ${pkgs.yazi}/bin/yazi";
      "Mod4+Shift+E" = "exec ${pkgs.nautilus}/bin/nautilus";
      "Mod4+M" = "exec spotify";
      "Mod4+O" = "exec ${pkgs.obsidian}/bin/obsidian";
      "Mod4+N" = "exec ${pkgs.foot}/bin/foot -e nvim";
      "Mod4+Shift+B" = "exec ${pkgs.foot}/bin/foot -e ${pkgs.bluetui}/bin/bluetui";
      "Mod4+Shift+N" = "exec ${noctalia} panel-toggle control-center";
      "Mod4+Escape" = "exec ${noctalia} panel-toggle session";
      "Mod4+Shift+W" = "exec ${noctalia} panel-toggle wallpaper";
      "Mod4+Shift+R" = "exec ${./reload.sh}";

      # Screenshots
      "Mod4+Shift+S" = "exec ${noctalia} screenshot-region";
      "Print" = "exec ${noctalia} screenshot-fullscreen";

      # Launcher / emoji / clipboard
      "Mod4+Space" = "exec ${noctalia} panel-toggle launcher";
      "Mod4+U" = "exec ${noctalia} panel-toggle launcher /emo";
      "Mod4+Y" = "exec ${noctalia} panel-toggle clipboard";

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

      # Resize windows
      "Mod4+Shift+H" = "resize grow width 50 px";
      "Mod4+Shift+L" = "resize shrink width 50 px";
      "Mod4+Shift+J" = "resize shrink height 50 px";
      "Mod4+Shift+K" = "resize grow height 50 px";

      # Multimedia keys
      "XF86AudioLowerVolume" = "exec ${noctalia} volume-down";
      "XF86AudioRaiseVolume" = "exec ${noctalia} volume-up";
      "XF86AudioMute" = "exec ${noctalia} volume-mute";
      "XF86AudioMicMute" = "exec ${noctalia} mic-mute";
      "XF86MonBrightnessUp" = lib.mkDefault "exec ${noctalia} brightness-up";
      "XF86MonBrightnessDown" = lib.mkDefault "exec ${noctalia} brightness-down";

      # Media keys
      "XF86AudioNext" = "exec ${noctalia} media next";
      "XF86AudioPause" = "exec ${noctalia} media toggle";
      "XF86AudioPlay" = "exec ${noctalia} media toggle";
      "XF86AudioPrev" = "exec ${noctalia} media previous";
    };
  };
}
