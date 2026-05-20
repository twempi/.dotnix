{
  wayland.windowManager.hyprland.settings = {
    windowrule = [
      # Picture-in-Picture
      "match:title ^(Picture-in-Picture)$, rounding 0"
      "match:title ^(Picture-in-Picture)$, border_size 0"
      "match:title ^(Picture-in-Picture)$, no_shadow on"

      # Calculator
      "match:class ^(org.gnome.Calculator)$, size 400 600"

      # Float/center popups & dialogs
      "match:title ^(Authentication Required)$, float on"
      "match:title ^(Authentication Required)$, center on"

      "match:title ^(Open File)(.*)$, center on"
      "match:title ^(Select a File)(.*)$, center on"
      "match:title ^(Open Folder)(.*)$, center on"
      "match:title ^(Save As)(.*)$, center on"
      "match:title ^(Library)(.*)$, center on"
      "match:title ^(File Upload)(.*)$, center on"

      "match:title ^(Open File)(.*)$, float on"
      "match:title ^(Select a File)(.*)$, float on"
      "match:title ^(Open Folder)(.*)$, float on"
      "match:title ^(Save As)(.*)$, float on"
      "match:title ^(Library)(.*)$, float on"
      "match:title ^(File Upload)(.*)$, float on"

      # Always-float apps
      "match:class ^(waypaper)$, float on, center on"
      "match:class ^(steam|Steam)$, float on, center on"
      "match:class ^(io.github.kaii_lb.Overskride)$, float on, center on"
      "match:class ^(nm-connection-editor)$, float on, center on"
      "match:class ^(org.gnome.Calculator)$, float on, center on"
      "match:class ^(openrgb)$, float on, center on"
      "match:class ^(heroic)$, float on, center on"
      "match:class ^(nwg-look)$, float on, center on"
      "match:class ^(org.pulseaudio.pavucontrol)$, float on, center on"

      "match:class ^(Spotify|spotify)$, workspace 9 silent"
      "match:class ^(Obsidian|obsidian)$, workspace 10 silent"
    ];

    # keep layerrule as-is
    layerrule = [
      "match:namespace rofi, animation on"
      "match:namespace rofi, dim_around on"
      "match:namespace logout_dialog, blur on"
      "match:namespace logout_dialog, xray on"
    ];
  };
}
