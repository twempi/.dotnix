import QtQuick
import QtQuick.Layouts

Item {
    id: root
    implicitWidth: col.implicitWidth
    implicitHeight: 36

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    Column {
        id: col
        anchors.centerIn: parent
        spacing: 0

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatTime(clock.date, "hh:mm:ss")
            font.pixelSize: 13
            font.family: "JetBrains Mono"
            font.weight: Font.Medium
            color: "#cdd6f4"

            Behavior on text {
                SequentialAnimation {
                    NumberAnimation { target: timeLabel; property: "opacity"; to: 0; duration: 60 }
                    PropertyAction  {}
                    NumberAnimation { target: timeLabel; property: "opacity"; to: 1; duration: 60 }
                }
            }
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDate(clock.date, "ddd, MMM d")
            font.pixelSize: 9
            font.family: "JetBrains Mono"
            color: "#6c7086"
            letterSpacing: 1
        }
    }
}
