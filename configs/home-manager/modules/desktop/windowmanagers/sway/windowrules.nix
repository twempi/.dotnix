{lib, ...}: let
  matchApp = re: [
    {app_id = re;}
    {class = re;}
  ];

  forApp = re: command:
    map (criteria: {inherit criteria command;}) (matchApp re);

  popupTitles = [
    "^(Authentication Required)$"
    "^(Open File)(.*)$"
    "^(Select a File)(.*)$"
    "^(Open Folder)(.*)$"
    "^(Save As)(.*)$"
    "^(Library)(.*)$"
    "^(File Upload)(.*)$"
  ];

  alwaysFloatCenterApps = [
    "^(waypaper)$"
    "^(steam|Steam)$"
    "^(io.github.kaii_lb.Overskride)$"
    "^(nm-connection-editor)$"
    "^(openrgb)$"
    "^(heroic)$"
    "^(nwg-look)$"
    "^(org.pulseaudio.pavucontrol)$"
  ];

  floatCenter = "floating enable, move position center";
in {
  wayland.windowManager.sway.config = {
    window.commands =
      [
        {
          criteria = {title = "^(Picture-in-Picture)$";};
          command = "border pixel 0";
        }
      ]
      ++ forApp "^(org.gnome.Calculator)$"
      "floating enable, resize set width 400 px height 600 px, move position center"
      ++ lib.flatten (map (title: [
          {
            criteria = {inherit title;};
            command = floatCenter;
          }
        ])
        popupTitles)
      # Always-float apps
      ++ lib.flatten (map (app: forApp app floatCenter) alwaysFloatCenterApps);

    assigns = {
      "9" = matchApp "^(Spotify|spotify)$";
      "10" = matchApp "^(Obsidian|obsidian)$";
    };
  };
}
