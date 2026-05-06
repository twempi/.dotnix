{ lib, ... }:

let
  # Sway separates native Wayland app_id and XWayland class.
  # Hyprland "class" often maps conceptually to one or the other,
  # so this duplicates app rules for both.
  matchApp = re: [
    { app_id = re; }
    { class = re; }
  ];

  forApp = re: command:
    map (criteria: { inherit criteria command; }) (matchApp re);

  popupTitles = [
    "^(Authentication Required)$"
    "^(Open File)(.*)$"
    "^(Select a File)(.*)$"
    "^(Choose wallpaper)(.*)$"
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
in
{
  wayland.windowManager.sway.config = {
    # Hyprland:
    # workspace = "1, monitor:DP-6";
    #
    # Sway/Home Manager equivalent:
    # workspaceOutputAssign = [
    #   { workspace = "1"; output = "DP-6"; }
    # ];

    window.commands =
      [
        # Picture-in-Picture
        #
        # Hyprland rounding/shadow rules do not have vanilla Sway equivalents.
        # border_size 0 -> border pixel 0
        {
          criteria = { title = "^(Picture-in-Picture)$"; };
          command = "border pixel 0";
        }

        # Calculator size + float + center
      ]
      ++ forApp "^(org.gnome.Calculator)$"
        "floating enable, resize set width 400 px height 600 px, move position center"

      # Float/center popups & dialogs
      ++ lib.flatten (map (title: [
        {
          criteria = { inherit title; };
          command = floatCenter;
        }
      ]) popupTitles)

      # Always-float apps
      ++ lib.flatten (map (app: forApp app floatCenter) alwaysFloatCenterApps);

    # Hyprland "workspace 9 silent" / "workspace 10 silent"
    # Sway's assign sends matching windows to workspaces when they appear.
    assigns = {
      "9" = matchApp "^(Spotify)$";
      "10" = matchApp "^(Obsidian)$";
    };
  };
}
