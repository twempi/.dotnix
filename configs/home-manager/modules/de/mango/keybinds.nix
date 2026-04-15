{...}: {
  xdg.configFile."mango/conf.d/keybinds.conf".text = ''
    bind=SUPER,Q,killclient
    bind=SUPER+SHIFT,Q,killclient
    bind=SUPER,V,togglefloating
    bind=SUPER,F,togglefullscreen

    bind=SUPER,Return,spawn,kitty
    bind=SUPER,B,spawn,zen-beta
    bind=SUPER,E,spawn,kitty -e yazi
    bind=SUPER+SHIFT,E,spawn,nautilus
    bind=SUPER,M,spawn,spotify
    bind=SUPER,O,spawn,obsidian
    bind=SUPER,N,spawn,kitty -e nvim
    bind=SUPER+SHIFT,B,spawn,kitty -e bluetui
    bind=SUPER+SHIFT,N,spawn,swaync-client -t -sw
    bind=SUPER,Escape,spawn,rofi-power

    bind=SUPER,Z,spawn,hyprpicker -a
    bind=SUPER+SHIFT,W,spawn,rofi-wallpaper

    bind=SUPER+SHIFT,S,spawn,bash ~/.config/hypr/scripts/screenshot.sh
    bind=NONE,Print,spawn_shell,grim - | wl-copy && wl-paste > ~/Pictures/Screenshots/Screenshot-$(date +%F_%T).png

    bind=SUPER,Space,spawn,rofi -show drun
    bind=SUPER,U,spawn,bemoji
    bind=SUPER,Y,spawn_shell,cliphist list | rofi -dmenu | cliphist decode | wl-copy

    bind=SUPER,H,focusdir,left
    bind=SUPER,L,focusdir,right
    bind=SUPER,J,focusdir,down
    bind=SUPER,K,focusdir,up

    bind=SUPER+CTRL,H,exchange_client,left
    bind=SUPER+CTRL,L,exchange_client,right
    bind=SUPER+CTRL,J,exchange_client,down
    bind=SUPER+CTRL,K,exchange_client,up

    bind=SUPER,1,view,1
    bind=SUPER,2,view,2
    bind=SUPER,3,view,3
    bind=SUPER,4,view,4
    bind=SUPER,5,view,5
    bind=SUPER,6,view,6
    bind=SUPER,7,view,7
    bind=SUPER,8,view,8
    bind=SUPER,9,view,9

    bind=SUPER+SHIFT,1,tag,1
    bind=SUPER+SHIFT,2,tag,2
    bind=SUPER+SHIFT,3,tag,3
    bind=SUPER+SHIFT,4,tag,4
    bind=SUPER+SHIFT,5,tag,5
    bind=SUPER+SHIFT,6,tag,6
    bind=SUPER+SHIFT,7,tag,7
    bind=SUPER+SHIFT,8,tag,8
    bind=SUPER+SHIFT,9,tag,9

    bind=NONE,XF86AudioLowerVolume,spawn,wpctl set-volume @DEFAULT_SINK@ 5%-
    bind=NONE,XF86AudioRaiseVolume,spawn,wpctl set-volume @DEFAULT_SINK@ 5%+
    bind=NONE,XF86AudioMute,spawn,wpctl set-mute @DEFAULT_SINK@ toggle
    bind=NONE,XF86AudioMicMute,spawn,wpctl set-mute @DEFAULT_SOURCE@ toggle
    bind=NONE,XF86MonBrightnessUp,spawn,brightnessctl set 5%+
    bind=NONE,XF86MonBrightnessDown,spawn,brightnessctl set 5%-

    bind=NONE,XF86AudioNext,spawn,playerctl next
    bind=NONE,XF86AudioPause,spawn,playerctl play-pause
    bind=NONE,XF86AudioPlay,spawn,playerctl play-pause
    bind=NONE,XF86AudioPrev,spawn,playerctl previous
  '';
}
