import QtQuick
import QtQuick.Layouts

Item {
    id: root
    implicitWidth: row.implicitWidth
    implicitHeight: 36

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        VolumeWidget {}

        NetworkWidget {}

        TaskCenterButton {}
    }
}
