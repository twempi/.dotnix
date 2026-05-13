{...}: let
  tagRules =
    builtins.genList
    (i: "id:${toString (i + 1)},layout_name:dwindle")
    10;
in {
  wayland.windowManager.mango.settings = {
    monitorrule = [
      "name:^eDP-1$,width:1920,height:1080,refresh:60,x:0,y:0,scale:1"
      "name:^DP-1$,width:2560,height:1440,refresh:180,x:0,y:0,scale:1"
      "name:^HDMI-A-2$,width:1920,height:1080,refresh:70,x:1920,y:0,scale:1"
    ];

    gappih = 3;
    gappiv = 3;
    gappoh = 5;
    gappov = 5;
    borderpx = 2;
    border_radius = 0;
    focused_opacity = 1.0;
    unfocused_opacity = 0.9;

    blur = 1;
    blur_layer = 1;
    blur_optimized = 1;
    blur_params_radius = 6;
    blur_params_num_passes = 2;

    shadows = 1;
    layer_shadows = 1;
    shadow_only_floating = 1;
    shadows_size = 5;
    shadows_blur = 12;

    numlockon = 1;
    xkb_rules_layout = "us";
    trackpad_natural_scrolling = 0;

    # mouse settings
    mouse_accel_profile = 1;
    mouse_accel_speed = 0.0;

    # trackpad settings
    tagrule = tagRules;
  };
}
