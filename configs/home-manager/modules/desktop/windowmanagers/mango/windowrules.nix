{...}: {
  wayland.windowManager.mango.settings = {
    windowrule = [
      "isfloating:1,width:400,height:600,appid:^(org.gnome.Calculator)$"
      "isfloating:1,isnoborder:1,title:^(Picture-in-Picture)$"
      "isfloating:1,title:^(Open File|Save File|Save As|Choose File|File Upload)$"

      "isfloating:1,appid:^(steam|Steam)$"
      "isfloating:1,appid:^(io.github.kaii_lb.Overskride)$"
      "isfloating:1,appid:^(nm-connection-editor)$"
      "isfloating:1,appid:^(openrgb)$"
      "isfloating:1,appid:^(heroic)$"
      "isfloating:1,appid:^(nwg-look)$"
      "isfloating:1,appid:^(org.pulseaudio.pavucontrol)$"
      "isfloating:1,appid:^(io.github.alainm23.planify.quick-add)$"

      "tags:9,isopensilent:1,appid:^(Spotify|spotify)$"
      "tags:10,isopensilent:1,appid:^(Obsidian|obsidian)$"
    ];

    layerrule = [
      "noanim:1,noblur:1,layer_name:^(selection)$"
      "noblur:1,layer_name:^(swaync)$"
      "noblur:1,layer_name:^(qs-launcher|qs-emoji|qs-clipboard|qs-power|qs-gpu|qs-wallpaper|qs-panel)$"
    ];
  };
}
