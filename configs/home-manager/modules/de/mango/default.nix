{inputs, ...}: {
  imports = [
    inputs.mangowm.hmModules.mango
    ./general.nix
    ./env.nix
    ./windowrules.nix
    ./keybinds.nix
  ];

  xdg.configFile."mango/conf.d/general.conf".text = ''
    monitorrule=name:^eDP-1$,width:1920,height:1080,refresh:60,x:0,y:0,scale:1
    monitorrule=name:^HDMI-A-2$,width:1920,height:1080,refresh:70,x:1920,y:0,scale:1

    gappih=3
    gappiv=3
    gappoh=5
    gappov=5
    borderpx=2
    border_radius=0
    focused_opacity=1.0
    unfocused_opacity=0.9

    blur=1
    blur_layer=1
    blur_optimized=1
    blur_params_radius=6
    blur_params_num_passes=2

    shadows=1
    layer_shadows=1
    shadow_only_floating=1
    shadows_size=5
    shadows_blur=12

    numlockon=1
    xkb_rules_layout=us
    trackpad_natural_scrolling=0
  '';

  xdg.configFile."mango/conf.d/env.conf".text = ''
    env=WLR_DRM_NO_ATOMIC,1
    env=WLR_RENDERER_ALLOW_SOFTWARE,1
    env=WLR_USE_LIBINPUT,1
    env=WLR_NO_HARDWARE_CURSORS,1
    env=XDG_SESSION_TYPE,wayland
    env=XDG_SESSION_DESKTOP,Mango
    env=XCURSOR_SIZE,24
    env=QT_QPA_PLATFORM,wayland
  '';

  xdg.configFile."mango/conf.d/rules.conf".text = ''
    windowrule=isfloating:1,width:400,height:600,appid:^(org.gnome.Calculator)$

    windowrule=isfloating:1,appid:^(waypaper)$
    windowrule=isfloating:1,appid:^(steam|Steam)$
    windowrule=isfloating:1,appid:^(io.github.kaii_lb.Overskride)$
    windowrule=isfloating:1,appid:^(nm-connection-editor)$
    windowrule=isfloating:1,appid:^(openrgb)$
    windowrule=isfloating:1,appid:^(heroic)$
    windowrule=isfloating:1,appid:^(nwg-look)$
    windowrule=isfloating:1,appid:^(org.pulseaudio.pavucontrol)$

    windowrule=tags:9,isopensilent:1,appid:^(Spotify)$
    windowrule=tags:8,isopensilent:1,appid:^(Obsidian)$
  '';

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

  wayland.windowManager.mango = {
    enable = true;
    settings = ''
      source=~/.config/mango/conf.d/general.conf
      source=~/.config/mango/conf.d/env.conf
      source=~/.config/mango/conf.d/rules.conf
      source=~/.config/mango/conf.d/keybinds.conf
    '';
    autostart_sh = ''
      awww-daemon
      openrgb --profile ~/.config/OpenRGB/black.orp
      waybar -c ~/.config/waybar/hyprland.jsonc -s ~/.config/waybar/hyprland.css

      wpctl set-volume @DEFAULT_SINK@ 1

      cliphist wipe
      wl-paste --type text --watch cliphist store
      spotify
      obsidian
    '';
  };

  home.sessionVariables = {
    NIXOS_OZONE_WL = 1;
    MOZ_ENABLE_WAYLAND = 1;
    XDG_SESSION_TYPE = "wayland";
    GDK_BACKEND = "wayland,x11";
    QT_QPA_PLATFORM = "wayland;xcb";
  };
}
