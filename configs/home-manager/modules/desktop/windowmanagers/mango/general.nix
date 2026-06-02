let
  tagRules =
    builtins.genList
    (i: "id:${toString (i + 1)},layout_name:dwindle")
    9;
in {
  wayland.windowManager.mango.settings = {
    gappih = 4;
    gappiv = 4;
    gappoh = 4;
    gappov = 4;
    borderpx = 2;
    border_radius = 0;
    focused_opacity = 1.0;
    unfocused_opacity = 0.9;

    blur = 1;
    blur_layer = 0;
    blur_optimized = 1;
    blur_params_radius = 6;
    blur_params_num_passes = 2;

    shadows = 1;
    layer_shadows = 1;
    shadow_only_floating = 1;
    shadows_size = 5;
    shadows_blur = 12;

    # Animation settings
    animations = 1;
    layer_animations = 1;

    animation_type_open = "zoom";
    animation_type_close = "zoom";

    animation_fade_in = 1;
    animation_fade_out = 1;

    # 1 = horizontal, 0 = vertical
    tag_animation_direction = 1;

    zoom_initial_ratio = 0.4;
    zoom_end_ratio = 0.8;

    fadein_begin_opacity = 0.5;
    fadeout_begin_opacity = 0.3;

    animation_duration_move = 500;
    animation_duration_open = 400;
    animation_duration_tag = 350;
    animation_duration_close = 150;
    animation_duration_focus = 0;

    animation_curve_open = "0.46,1.0,0.29,1";
    animation_curve_move = "0.46,1.0,0.29,1";
    animation_curve_tag = "0.46,1.0,0.29,1";
    animation_curve_close = "0.08,0.92,0,1";
    animation_curve_focus = "0.46,1.0,0.29,1";
    animation_curve_opafadeout = "0.5,0.5,0.5,0.5";
    animation_curve_opafadein = "0.46,1.0,0.29,1";

    numlockon = 1;
    xkb_rules_layout = "us";
    trackpad_natural_scrolling = 0;

    # mouse settings
    mouse_accel_profile = 1;
    mouse_accel_speed = 0.0;

    # trackpad settings
    trackpad_accel_profile = 0;
    trackpad_accel_speed = 0.5;
    disable_while_typing = 0;

    syncobj_enable = 0;

    tagrule = tagRules;
  };
}
