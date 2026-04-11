# {pkgs, ...}: {
#   home.packages = with pkgs; [
#     quickshell
#     jq
#     socat
#     pamixer
#     brightnessctl
#     wl-clipboard
#     cliphist
#     bluez
#     networkmanager
#     imagemagick
#     qt6.qtmultimedia
#     qt6.qt5compat
#     qt6.qtwebsockets
#     ffmpeg
#   ];
#
#   programs.quickshell = {
#     enable = true;
#   };
#
#   xdg.configFile."hypr/scripts".source = ./scripts;
# }


{ config, pkgs, inputs, ... }:

{
  # Add quickshell to your package set via overlay
  programs.quickshell = {
    enable = true;

    # Point to the config you want active
    activeConfig = "bar";

    # Inline your QML files declaratively
    configs."bar" = {
      # shell.qml is the entry point — must be named shell.qml
      "shell.qml".text = builtins.readFile ./quickshell/shell.qml;
      "WorkspacesWidget.qml".text   = builtins.readFile ./quickshell/WorkspacesWidget.qml;
      "WorkspaceButton.qml".text    = builtins.readFile ./quickshell/WorkspaceButton.qml;
      "ClockWidget.qml".text        = builtins.readFile ./quickshell/ClockWidget.qml;
      "SystemTrayWidget.qml".text   = builtins.readFile ./quickshell/SystemTrayWidget.qml;
      "VolumeWidget.qml".text       = builtins.readFile ./quickshell/VolumeWidget.qml;
      "NetworkWidget.qml".text      = builtins.readFile ./quickshell/NetworkWidget.qml;
      "TaskCenterButton.qml".text   = builtins.readFile ./quickshell/TaskCenterButton.qml;
    };

    # Auto-start as a systemd user service
    systemd.enable = true;
  };

  # Required fonts for the Nerd Font glyphs
  fonts.fontconfig.enable = true;
  home.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
  ];
}
