{...}: {
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
}
