{...}: {
  wayland.windowManager.mango.settings = {
    bind = [
      "SUPER,Q,killclient"
      "SUPER+SHIFT,Q,killclient"
      "SUPER,V,togglefloating"
      "SUPER,F,togglefullscreen"

      "SUPER,Return,spawn,kitty"
      # "SUPER,B,spawn,zen-beta"
      "SUPER,B,spawn,helium"
      "SUPER,E,spawn,kitty -e yazi"
      "SUPER+SHIFT,E,spawn,nautilus"
      "SUPER,M,spawn,spotify"
      "SUPER,O,spawn,obsidian"
      "SUPER,N,spawn,kitty -e nvim"
      "SUPER+SHIFT,B,spawn,kitty -e bluetui"
      "SUPER+SHIFT,N,spawn,swaync-client -t -sw"
      "SUPER+SHIFT,R,spawn,bash ${./reload.sh}"
      "SUPER,Escape,spawn,qs-power"

      "SUPER,Z,spawn,hyprpicker -a"
      "SUPER+SHIFT,W,spawn,qs-wallpaper"

      "SUPER+SHIFT,S,spawn,bash ${./screenshot.sh}"
      "NONE,Print,spawn_shell,grim - | wl-copy && wl-paste > ~/Pictures/Screenshots/Screenshot-$(date +%F_%T).png"

      "SUPER,Space,spawn,qs-launcher"
      "SUPER,U,spawn,bemoji"
      "SUPER,Y,spawn_shell,cliphist list | rofi -dmenu | cliphist decode | wl-copy"

      "SUPER,H,focusdir,left"
      "SUPER,L,focusdir,right"
      "SUPER,J,focusdir,down"
      "SUPER,K,focusdir,up"

      "SUPER+CTRL,H,exchange_client,left"
      "SUPER+CTRL,L,exchange_client,right"
      "SUPER+CTRL,J,exchange_client,down"
      "SUPER+CTRL,K,exchange_client,up"

      "SUPER,1,view,1"
      "SUPER,2,view,2"
      "SUPER,3,view,3"
      "SUPER,4,view,4"
      "SUPER,5,view,5"
      "SUPER,6,view,6"
      "SUPER,7,view,7"
      "SUPER,8,view,8"
      "SUPER,9,view,9"

      "SUPER+SHIFT,1,tag,1"
      "SUPER+SHIFT,2,tag,2"
      "SUPER+SHIFT,3,tag,3"
      "SUPER+SHIFT,4,tag,4"
      "SUPER+SHIFT,5,tag,5"
      "SUPER+SHIFT,6,tag,6"
      "SUPER+SHIFT,7,tag,7"
      "SUPER+SHIFT,8,tag,8"
      "SUPER+SHIFT,9,tag,9"

      "NONE,XF86AudioLowerVolume,spawn,wpctl set-volume @DEFAULT_SINK@ 5%-"
      "NONE,XF86AudioRaiseVolume,spawn,wpctl set-volume @DEFAULT_SINK@ 5%+"
      "NONE,XF86AudioMute,spawn,wpctl set-mute @DEFAULT_SINK@ toggle"
      "NONE,XF86AudioMicMute,spawn,wpctl set-mute @DEFAULT_SOURCE@ toggle"
      "NONE,XF86MonBrightnessUp,spawn,brightnessctl set 5%+"
      "NONE,XF86MonBrightnessDown,spawn,brightnessctl set 5%-"

      "NONE,XF86AudioNext,spawn,playerctl next"
      "NONE,XF86AudioPause,spawn,playerctl play-pause"
      "NONE,XF86AudioPlay,spawn,playerctl play-pause"
      "NONE,XF86AudioPrev,spawn,playerctl previous"
    ];
  };
}
