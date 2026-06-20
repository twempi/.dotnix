{
  wayland.windowManager.mango.settings = {
    monitorrule = [
      # Main 1440p monitor
      "name:^DP-2$,width:2560,height:1440,refresh:180,x:0,y:0,scale:1.0,vrr:0"

      # Secondary 1080p HDMI monitor to the right
      "name:^HDMI-A-1$,width:1920,height:1080,refresh:60,x:2560,y:0,scale:1.0,vrr:0"
    ];
  };
}
