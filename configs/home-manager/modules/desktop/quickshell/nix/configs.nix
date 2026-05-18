{
  config,
  pkgs,
}:
let
  styleQml = pkgs.writeText "quickshell-style.qml" ''
    import QtQuick

    QtObject {
      readonly property string fontFamily: "JetBrainsMono Nerd Font"
      readonly property color background: "#${config.lib.stylix.colors.base00}"
      readonly property color backgroundAlt: "#${config.lib.stylix.colors.base01}"
      readonly property color foreground: "#${config.lib.stylix.colors.base05}"
      readonly property color foregroundAlt: "#${config.lib.stylix.colors.base06}"
      readonly property color muted: "#${config.lib.stylix.colors.base04}"
      readonly property color border: "#${config.lib.stylix.colors.base03}"
      readonly property color accent: "#${config.lib.stylix.colors.base0A}"
      readonly property color urgent: "#${config.lib.stylix.colors.base08}"
      readonly property color selectedForeground: "#${config.lib.stylix.colors.base00}"
    }
  '';
  wallpaperPickerConfig = pkgs.runCommandLocal "quickshell-wallpaper-picker-config" {} ''
    mkdir -p "$out"
    cp ${../wallpaper-picker/shell.qml} "$out/shell.qml"
    cp ${../wallpaper-picker/WallpaperCard.qml} "$out/WallpaperCard.qml"
    cp ${styleQml} "$out/Style.qml"
  '';
  appLauncherConfig = pkgs.runCommandLocal "quickshell-app-launcher-config" {} ''
    mkdir -p "$out"
    cp ${../app-launcher/shell.qml} "$out/shell.qml"
    cp ${../app-launcher/AppRow.qml} "$out/AppRow.qml"
    cp ${styleQml} "$out/Style.qml"
  '';
  powerMenuConfig = pkgs.runCommandLocal "quickshell-power-menu-config" {} ''
    mkdir -p "$out"
    cp ${../power-menu/shell.qml} "$out/shell.qml"
    cp ${styleQml} "$out/Style.qml"
    cp -r ${../power-menu/icons} "$out/icons"
  '';
  quickActionsConfig = pkgs.runCommandLocal "quickshell-quick-actions-config" {} ''
    mkdir -p "$out"
    cp ${../quick-actions/shell.qml} "$out/shell.qml"
    cp ${../quick-actions/PickerRow.qml} "$out/PickerRow.qml"
    cp ${../app-launcher/AppRow.qml} "$out/AppRow.qml"
    cp ${../wallpaper-picker/WallpaperCard.qml} "$out/WallpaperCard.qml"
    cp ${styleQml} "$out/Style.qml"
    cp -r ${../power-menu/icons} "$out/icons"
  '';
  topBarConfig = pkgs.runCommandLocal "quickshell-top-bar-config" {} ''
    mkdir -p "$out"
    cp ${../top-bar/shell.qml} "$out/shell.qml"
    cp ${styleQml} "$out/Style.qml"
  '';
in {
  inherit
    appLauncherConfig
    powerMenuConfig
    quickActionsConfig
    styleQml
    topBarConfig
    wallpaperPickerConfig
    ;

  configs = {
    app-launcher = appLauncherConfig;
    power-menu = powerMenuConfig;
    quick-actions = quickActionsConfig;
    top-bar = topBarConfig;
    wallpaper-picker = wallpaperPickerConfig;
  };
}
