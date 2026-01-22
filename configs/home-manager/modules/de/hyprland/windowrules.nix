{
  wayland.windowManager.hyprland.settings = {
    # workspace = "1, monitor:DP-6";

    windowrule = [
      # PiP windows
      "match:title ^(Picture-in-Picture)$, pin on"
      "match:title ^(Picture-in-Picture)$, keep_aspect_ratio on"
      "match:title ^(Picture-in-Picture)$, float on"

      # GNOME Calculator
      "match:class ^(org.gnome.Calculator)$, float on"

      # Waypaper
      "match:class ^(waypaper)$, float on"

      # XWayland video bridge fix
      "match:class ^(xwaylandvideobridge)$, opacity 0.0 override"
      "match:class ^(xwaylandvideobridge)$, no_initial_focus on"
      "match:class ^(xwaylandvideobridge)$, max_size 1 1"
      "match:class ^(xwaylandvideobridge)$, no_blur on"
      "match:class ^(xwaylandvideobridge)$, no_focus on"

      # Ignore maximize requests from apps
      "match:class .*, suppress_event maximize"

      # Fix some dragging issues with XWayland
      "match:class ^$, match:title ^$, match:xwayland true, match:float true, match:fullscreen false, match:pin false, no_focus on"
    ];

    windowrulev2 = [
      # Picture-in-Picture PART 2
      "rounding 0, title:^(Picture-in-Picture)$"
      "noborder, title:^(Picture-in-Picture)$"
      "noshadow, title:^(Picture-in-Picture)$"

      # Calculator PART 2
      "size 400 600, class:^(org.gnome.Calculator)$"

      # windowrule - float popups and dialogue
      "float, title:^(Authentication Required)$"
      "center, title:^(Authentication Required)$"
      "center, title:^(Open File)(.*)$"
      "center, title:^(Select a File)(.*)$"
      "center, title:^(Choose wallpaper)(.*)$"
      "center, title:^(Open Folder)(.*)$"
      "center, title:^(Save As)(.*)$"
      "center, title:^(Library)(.*)$"
      "center, title:^(File Upload)(.*)$"
      "float, title:^(Open File)(.*)$"
      "float, title:^(Select a File)(.*)$"
      "float, title:^(Choose wallpaper)(.*)$"
      "float, title:^(Open Folder)(.*)$"
      "float, title:^(Save As)(.*)$"
      "float, title:^(Library)(.*)$"
      "float, title:^(File Upload)(.*)$"

      # Always float
      "float, center, class:^(waypaper)$"
      "float, center, class:^(steam|Steam)$"
      "float, center, class:^(io.github.kaii_lb.Overskride)$"
      "float, center, class:^(nm-connection-editor)$"
      "float, center, class:^(org.gnome.Calculator)$"
      "float, center, class:^(openrgb)$"
      "float, center, class:^(heroic)$"
      "float, center, class:^(nwg-look)$"
      "float, center, class:^(org.pulseaudio.pavucontrol)$"

      # Opacity
      # "opacity 0.9 0.8, class:^(org.pwmt.zathura)$"
    ];

    layerrule = [
      "animation on, match:namespace rofi"
      "dim_around on, match:namespace rofi"

      "blur on, match:namespace logout_dialog"
      "xray on, match:namespace logout_dialog"
    ];
  };
}
