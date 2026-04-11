import Quickshell
import Quickshell.Hyprland
import QtQuick

Rectangle {
    id: btn
    required property HyprlandWorkspace modelData

    width: modelData.id === HyprlandMonitor.focusedWorkspace?.id ? 26 : 20
    height: width
    radius: width / 2

    // Active = filled accent, occupied = dim accent, empty = muted
    color: {
        if (modelData.id === HyprlandMonitor.focusedWorkspace?.id)
            return "#89b4fa"
        if (modelData.clientCount > 0)
            return "#44585b70"
        return "#22585b70"
    }

    border.color: modelData.id === HyprlandMonitor.focusedWorkspace?.id
        ? "#89b4fa"
        : "#33cdd6f4"
    border.width: 1

    Behavior on width   { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
    Behavior on height  { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
    Behavior on color   { ColorAnimation  { duration: 150 } }
    Behavior on radius  { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

    Text {
        anchors.centerIn: parent
        text: modelData.id
        font.pixelSize: 10
        font.family: "JetBrains Mono"
        color: modelData.id === HyprlandMonitor.focusedWorkspace?.id
            ? "#1a1a2e" : "#89b4fa"
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Hyprland.dispatch(`workspace ${modelData.id}`)
    }

    // Hover glow
    HoverHandler { id: hover }
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: "transparent"
        border.color: "#6089b4fa"
        border.width: hover.hovered ? 2 : 0
        Behavior on border.width { NumberAnimation { duration: 120 } }
    }
}
