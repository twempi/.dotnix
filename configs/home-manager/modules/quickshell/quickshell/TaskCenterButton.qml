import Quickshell
import Quickshell.Hyprland
import QtQuick

Item {
    implicitWidth: 34
    implicitHeight: 36

    Rectangle {
        anchors.centerIn: parent
        width: 28
        height: 28
        radius: 8
        color: tcHover.hovered ? "#2289b4fa" : "#11cdd6f4"
        Behavior on color { ColorAnimation { duration: 120 } }

        HoverHandler { id: tcHover }

        // Grid of dots — task center / app grid icon
        Grid {
            anchors.centerIn: parent
            columns: 3
            spacing: 3
            Repeater {
                model: 9
                Rectangle {
                    width: 3
                    height: 3
                    radius: 1
                    color: "#89b4fa"
                    opacity: tcHover.hovered ? 1 : 0.6
                    Behavior on opacity { NumberAnimation { duration: 120 } }
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            // Toggle an overview / task view — adjust to your setup
            // Common options: rofi, anyrun, hyprexpo, etc.
            onClicked: Hyprland.dispatch("hyprexpo:expo toggle")
            // Or to launch rofi:
            // onClicked: Process.execute(["rofi", "-show", "drun"])
        }
    }
}
