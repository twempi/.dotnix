{...}: {
  wayland.windowManager.hyprland.settings = {
    window_rule = [
      # Picture-in-Picture
      {
        match.title = "^(Picture-in-Picture)$";
        rounding = 0;
        border_size = 0;
        no_shadow = true;
      }

      # Calculator
      {
        match.class = "^(org.gnome.Calculator)$";
        size = "400 600";
        float = true;
        center = true;
      }

      # Float/center popups & dialogs
      {
        match.title = "^(Authentication Required)$";
        float = true;
        center = true;
      }
      {
        match.title = "^(Open File)(.*)$";
        float = true;
        center = true;
      }
      {
        match.title = "^(Select a File)(.*)$";
        float = true;
        center = true;
      }
      {
        match.title = "^(Open Folder)(.*)$";
        float = true;
        center = true;
      }
      {
        match.title = "^(Save As)(.*)$";
        float = true;
        center = true;
      }
      {
        match.title = "^(Library)(.*)$";
        float = true;
        center = true;
      }
      {
        match.title = "^(File Upload)(.*)$";
        float = true;
        center = true;
      }

      # Always-float apps
      {
        match.class = "^(waypaper)$";
        float = true;
        center = true;
      }
      {
        match.class = "^(steam|Steam)$";
        float = true;
        center = true;
      }
      {
        match.class = "^(io.github.kaii_lb.Overskride)$";
        float = true;
        center = true;
      }
      {
        match.class = "^(nm-connection-editor)$";
        float = true;
        center = true;
      }
      {
        match.class = "^(openrgb)$";
        float = true;
        center = true;
      }
      {
        match.class = "^(heroic)$";
        float = true;
        center = true;
      }
      {
        match.class = "^(nwg-look)$";
        float = true;
        center = true;
      }
      {
        match.class = "^(org.pulseaudio.pavucontrol)$";
        float = true;
        center = true;
      }

      {
        match.class = "^(Spotify|spotify)$";
        workspace = "9 silent";
      }
      {
        match.class = "^(Obsidian|obsidian)$";
        workspace = "10 silent";
      }
    ];

    layer_rule = [
      {
        match.namespace = "rofi";
        animation = "on";
      }
      {
        match.namespace = "rofi";
        dim_around = true;
      }
      {
        match.namespace = "logout_dialog";
        blur = true;
      }
      {
        match.namespace = "logout_dialog";
        xray = true;
      }
    ];
  };
}
