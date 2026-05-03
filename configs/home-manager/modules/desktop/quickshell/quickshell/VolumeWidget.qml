import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Layouts

Item {
    id: root
    implicitHeight: 36
    implicitWidth: expanded ? 130 : 34
    clip: true

    property bool expanded: hover.hovered || sliderHover.hovered
    Behavior on implicitWidth { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

    HoverHandler { id: hover }

    // Grab the default audio sink from Pipewire
    PwNodeLinkWatcher { id: linkWatcher }

    property PwNode sink: Pipewire.defaultAudioSink
    property real volume: sink?.audio?.volume ?? 0
    property bool muted: sink?.audio?.muted ?? false

    Row {
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        spacing: 4
        layoutDirection: Qt.RightToLeft

        // Icon pill (always visible)
        Rectangle {
            width: 28
            height: 28
            radius: 8
            color: volIconHover.hovered ? "#2289b4fa" : "#11cdd6f4"
            Behavior on color { ColorAnimation { duration: 120 } }

            HoverHandler { id: volIconHover }

            Text {
                anchors.centerIn: parent
                text: root.muted ? "󰝟" : (root.volume > 0.6 ? "󰕾" : root.volume > 0.2 ? "󰖀" : "󰕿")
                font.pixelSize: 14
                font.family: "Symbols Nerd Font"
                color: root.muted ? "#f38ba8" : "#89b4fa"
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (root.sink?.audio)
                        root.sink.audio.muted = !root.sink.audio.muted
                }
            }
        }

        // Slider — visible only when expanded
        Item {
            width: root.expanded ? 88 : 0
            height: 28
            visible: root.implicitWidth > 50
            opacity: root.expanded ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 180 } }

            HoverHandler { id: sliderHover }

            // Track background
            Rectangle {
                id: track
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 8
                anchors.horizontalCenter: parent.horizontalCenter
                height: 4
                radius: 2
                color: "#33585b70"

                // Filled portion
                Rectangle {
                    width: parent.width * root.volume
                    height: parent.height
                    radius: parent.radius
                    color: root.muted ? "#f38ba8" : "#89b4fa"
                    Behavior on width { NumberAnimation { duration: 80 } }
                }

                // Thumb
                Rectangle {
                    x: (parent.width * root.volume) - width / 2
                    anchors.verticalCenter: parent.verticalCenter
                    width: 12
                    height: 12
                    radius: 6
                    color: "#cdd6f4"
                    border.color: "#89b4fa"
                    border.width: 2
                    Behavior on x { NumberAnimation { duration: 80 } }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.SizeHorCursor
                    onPressed: (mouse) => updateVolume(mouse.x)
                    onPositionChanged: (mouse) => {
                        if (pressed) updateVolume(mouse.x)
                    }
                    function updateVolume(mx) {
                        const v = Math.max(0, Math.min(1, mx / track.width))
                        if (root.sink?.audio) root.sink.audio.volume = v
                    }
                }
            }

            // Volume percentage label
            Text {
                anchors.right: parent.right
                anchors.rightMargin: 2
                anchors.verticalCenter: parent.verticalCenter
                text: Math.round(root.volume * 100) + "%"
                font.pixelSize: 8
                font.family: "JetBrains Mono"
                color: "#6c7086"
            }
        }
    }
}
