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
# {
#   config,
#   pkgs,
#   inputs,
#   ...
# }: {
#   programs.quickshell = {
#     enable = true;
#     activeConfig = "bar";
#     configs."bar" = ./quickshell;
#     package = inputs.quickshell.packages.${pkgs.system}.default;
#   };
#
#   fonts.fontconfig.enable = true;
#   # home.packages = with pkgs; [
#   #   nerd-fonts.jetbrains-mono
#   # ];
# }
{
  config,
  pkgs,
  inputs,
  ...
}: let
  wallpaperDir = "${config.home.homeDirectory}/Pictures/wallpapers";

  setWallpaper = pkgs.writeShellScriptBin "set-wallpaper" ''
    set -euo pipefail

    img="''${1:?usage: set-wallpaper /absolute/path/to/image}"
    cache_dir="$HOME/.cache"
    cache_file="$cache_dir/current-wallpaper"

    ${pkgs.coreutils}/bin/mkdir -p "$cache_dir"

    if ! ${pkgs.awww}/bin/awww query >/dev/null 2>&1; then
      ${pkgs.awww}/bin/awww-daemon >/dev/null 2>&1 &
      ${pkgs.coreutils}/bin/sleep 0.25
    fi

    printf '%s\n' "$img" > "$cache_file"

    ${pkgs.awww}/bin/awww img "$img" \
      --transition-type center \
      --transition-step 90 \
      --transition-fps 60 \
      >/dev/null

    printf 'Applied: %s\n' "''${img##*/}"
  '';

  restoreWallpaper = pkgs.writeShellScriptBin "restore-wallpaper" ''
    set -euo pipefail

    cache_file="$HOME/.cache/current-wallpaper"

    [[ -f "$cache_file" ]] || exit 0
    img="$(<"$cache_file")"
    [[ -f "$img" ]] || exit 0

    if ! ${pkgs.awww}/bin/awww query >/dev/null 2>&1; then
      ${pkgs.awww}/bin/awww-daemon >/dev/null 2>&1 &
      ${pkgs.coreutils}/bin/sleep 0.25
    fi

    ${pkgs.awww}/bin/awww img "$img" \
      --transition-type center \
      --transition-step 90 \
      --transition-fps 60 \
      >/dev/null
  '';

  toggleWallpaperSwitcher = pkgs.writeShellScriptBin "toggle-wallpaper-switcher" ''
    set -euo pipefail

    if ${pkgs.procps}/bin/pgrep -f "${pkgs.quickshell}/bin/quickshell --config wallpaper-switcher" >/dev/null 2>&1; then
      ${pkgs.procps}/bin/pkill -f "${pkgs.quickshell}/bin/quickshell --config wallpaper-switcher"
    else
      exec ${pkgs.quickshell}/bin/quickshell --config wallpaper-switcher
    fi
  '';
in {
  home.packages = [
    setWallpaper
    restoreWallpaper
    toggleWallpaperSwitcher
  ];

  programs.quickshell = {
    enable = true;
    package = inputs.quickshell.packages.${pkgs.system}.default;
  };

  home.file.".config/quickshell/wallpaper-switcher/shell.qml".text = ''
    import Quickshell
    import Quickshell.Io
    import QtQuick
    import QtQuick.Controls
    import QtQuick.Layouts
    import Qt.labs.folderlistmodel

    FloatingWindow {
        id: root
        visible: true
        title: "Wallpaper Switcher"
        color: "transparent"

        implicitWidth: 1100
        implicitHeight: 620

        property url wallpapersFolder: "file:///home/edward/Pictures/wallpapers"
        property string query: ""

        function matchesSearch(name) {
            if (query.trim() === "")
                return true
            return name.toLowerCase().indexOf(query.toLowerCase()) !== -1
        }

        function applyWallpaper(path) {
            applyProc.command = ["set-wallpaper", path]
            applyProc.running = true
        }

        Shortcut {
            sequence: "Escape"
            onActivated: Qt.quit()
        }

        Process {
            id: applyProc
            command: ["true"]
            running: false

            stdout: StdioCollector {
                onStreamFinished: Qt.quit()
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: 0
            color: "#25283b"
            border.width: 1
            border.color: "#00ff99"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 6
                spacing: 8

                TextField {
                    id: search
                    Layout.fillWidth: true
                    placeholderText: "Search..."
                    color: "#e6e6e6"
                    selectionColor: "#00ff99"
                    selectedTextColor: "#10131a"
                    text: root.query
                    onTextChanged: root.query = text

                    background: Rectangle {
                        color: "#2b2f42"
                        border.width: 1
                        border.color: "#00ff99"
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "transparent"
                    clip: true

                    FolderListModel {
                        id: folderModel
                        folder: root.wallpapersFolder
                        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp", "*.bmp"]
                        showDirs: false
                        showFiles: true
                        showHidden: false
                        showOnlyReadable: true
                        sortField: FolderListModel.Name
                    }

                    Flickable {
                        anchors.fill: parent
                        contentWidth: width
                        contentHeight: flow.implicitHeight
                        clip: true

                        Flow {
                            id: flow
                            width: parent.width
                            spacing: 12

                            Repeater {
                                model: folderModel

                                delegate: Item {
                                    required property string fileName
                                    required property string filePath
                                    required property url fileUrl

                                    property bool shown: root.matchesSearch(fileName)

                                    visible: shown
                                    width: shown ? 98 : 0
                                    height: shown ? 260 : 0

                                    Column {
                                        anchors.fill: parent
                                        spacing: 8

                                        Rectangle {
                                            width: 98
                                            height: 186
                                            color: thumbMouse.containsMouse ? "#00ff99" : "transparent"
                                            border.width: thumbMouse.containsMouse ? 0 : 0

                                            Rectangle {
                                                anchors {
                                                    left: parent.left
                                                    right: parent.right
                                                    top: parent.top
                                                    margins: 6
                                                }
                                                height: 180
                                                color: "#1d2130"
                                                clip: true

                                                Image {
                                                    anchors.fill: parent
                                                    source: fileUrl
                                                    fillMode: Image.PreserveAspectCrop
                                                    asynchronous: true
                                                    cache: false
                                                }
                                            }
                                        }

                                        Text {
                                            width: 98
                                            text: fileName
                                            horizontalAlignment: Text.AlignHCenter
                                            color: "#f2f2f2"
                                            font.pixelSize: 16
                                            elide: Text.ElideRight
                                        }
                                    }

                                    MouseArea {
                                        id: thumbMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: root.applyWallpaper(filePath)
                                    }
                                }
                            }
                        }

                        ScrollBar.vertical: ScrollBar {}
                    }
                }
            }
        }
    }
  '';

  wayland.windowManager.hyprland.settings = {
    bind = [
      "SUPER, W, exec, ${toggleWallpaperSwitcher}/bin/toggle-wallpaper-switcher"
    ];

    exec-once = [
      "${restoreWallpaper}/bin/restore-wallpaper"
    ];
  };
}
