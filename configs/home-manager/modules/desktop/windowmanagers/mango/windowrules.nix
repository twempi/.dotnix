{...}: {
  wayland.windowManager.mango.settings = {
    window_rule = [
      "is_floating:1,width:400,height:600,app_id:^(org.gnome.Calculator)$"
      "is_floating:1,no_border:1,title:^(Picture-in-Picture)$"
      "is_floating:1,title:^(Open File|Save File|Save As|Choose File|File Upload)$"

      "is_floating:1,app_id:^(steam|Steam)$"
      "is_floating:1,app_id:^(io.github.kaii_lb.Overskride)$"
      "is_floating:1,app_id:^(nm-connection-editor)$"
      "is_floating:1,app_id:^(openrgb)$"
      "is_floating:1,app_id:^(heroic)$"
      "is_floating:1,app_id:^(nwg-look)$"
      "is_floating:1,app_id:^(org.pulseaudio.pavucontrol)$"
      "is_floating:1,app_id:^(io.github.alainm23.planify.quick-add)$"

      "tags:9,is_open_silent:1,app_id:^(Spotify|spotify)$"
    ];

    layer_rule = [
      "no_animation:1,no_blur:1,layer_name:^(selection)$"
      "no_blur:1,layer_name:^(rofi)$"
    ];
  };
}
