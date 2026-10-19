{
  flake.modules.homeManager.niri = {
    programs.niri.settings.window-rules = [
      {
        matches = [{app-id = "^(Spotify|spotify)$";}];
        open-on-workspace = "9";
      }
      {
        matches = [{app-id = "^(Obsidian|obsidian)$";}];
        open-on-workspace = "10";
      }
      {
        matches = [
          {app-id = "^(steam|Steam|io.github.kaii_lb.Overskride|nm-connection-editor|openrgb|heroic|nwg-look|org.pulseaudio.pavucontrol)$";}
          {title = "^(Authentication Required|Open File.*|Select a File.*|Open Folder.*|Save As.*|Library.*|File Upload.*)$";}
          {title = "^Picture-in-Picture$";}
        ];
        open-floating = true;
      }
      {
        matches = [{app-id = "^org.gnome.Calculator$";}];
        open-floating = true;
        default-column-width.fixed = 400;
        default-window-height.fixed = 600;
      }
    ];
  };
}
