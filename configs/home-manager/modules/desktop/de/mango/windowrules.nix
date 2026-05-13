{...}: {
  wayland.windowManager.mango.settings = {
    windowrule = [
      "isfloating:1,width:400,height:600,appid:^(org.gnome.Calculator)$"
      "isfloating:1,isnoborder:1,title:^(Picture-in-Picture)$"
      "isfloating:1,title:^(Open File|Save File|Save As|Choose File|File Upload)$"

      "isfloating:1,appid:^(waypaper)$"
      "isfloating:1,appid:^(steam|Steam)$"
      "isfloating:1,appid:^(io.github.kaii_lb.Overskride)$"
      "isfloating:1,appid:^(nm-connection-editor)$"
      "isfloating:1,appid:^(openrgb)$"
      "isfloating:1,appid:^(heroic)$"
      "isfloating:1,appid:^(nwg-look)$"
      "isfloating:1,appid:^(org.pulseaudio.pavucontrol)$"
      "isfloating:1,appid:^(io.github.alainm23.planify.quick-add)$"

      "tags:9,isopensilent:1,appid:^(Spotify)$"
      "tags:10,isopensilent:1,appid:^(Obsidian)$"
    ];
  };
}
