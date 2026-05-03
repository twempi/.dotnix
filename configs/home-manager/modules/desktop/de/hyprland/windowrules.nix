{
  wayland.windowManager.hyprland.settings = {
    # workspace = "1, monitor:DP-6";

    windowrule = [
      # Picture-in-Picture (was windowrulev2)
      "rounding 0, match:title ^(Picture-in-Picture)$"
      # "noborder" doesn't exist in the new list; use border_size 0 instead
      "border_size 0, match:title ^(Picture-in-Picture)$"
      # "noshadow" -> no_shadow on
      "no_shadow on, match:title ^(Picture-in-Picture)$"

      # Calculator (was windowrulev2)
      "size 400 600, match:class ^(org.gnome.Calculator)$"

      # Float/center popups & dialogs (was windowrulev2)
      "float on, match:title ^(Authentication Required)$"
      "center on, match:title ^(Authentication Required)$"

      "center on, match:title ^(Open File)(.*)$"
      "center on, match:title ^(Select a File)(.*)$"
      "center on, match:title ^(Choose wallpaper)(.*)$"
      "center on, match:title ^(Open Folder)(.*)$"
      "center on, match:title ^(Save As)(.*)$"
      "center on, match:title ^(Library)(.*)$"
      "center on, match:title ^(File Upload)(.*)$"

      "float on, match:title ^(Open File)(.*)$"
      "float on, match:title ^(Select a File)(.*)$"
      "float on, match:title ^(Choose wallpaper)(.*)$"
      "float on, match:title ^(Open Folder)(.*)$"
      "float on, match:title ^(Save As)(.*)$"
      "float on, match:title ^(Library)(.*)$"
      "float on, match:title ^(File Upload)(.*)$"

      # Always-float apps (was windowrulev2)
      "float on, center on, match:class ^(waypaper)$"
      "float on, center on, match:class ^(steam|Steam)$"
      "float on, center on, match:class ^(io.github.kaii_lb.Overskride)$"
      "float on, center on, match:class ^(nm-connection-editor)$"
      "float on, center on, match:class ^(org.gnome.Calculator)$"
      "float on, center on, match:class ^(openrgb)$"
      "float on, center on, match:class ^(heroic)$"
      "float on, center on, match:class ^(nwg-look)$"
      "float on, center on, match:class ^(org.pulseaudio.pavucontrol)$"

      "match:class ^(Spotify)$, workspace 9 silent"
      "match:class ^(Obsidian)$, workspace 10 silent"
    ];

    # keep layerrule as-is
    layerrule = [
      "animation on, match:namespace rofi"
      "dim_around on, match:namespace rofi"
      "blur on, match:namespace logout_dialog"
      "xray on, match:namespace logout_dialog"
    ];
  };
}
