import Quickshell
import Quickshell.Widgets
import QtQuick

Item {
  id: row

  property var app
  property bool selected: false

  signal clicked()

  readonly property string appName: app ? (app.name || app.id || "") : ""
  readonly property string description: app ? (app.genericName || app.comment || app.id || "") : ""
  readonly property string iconSource: app && app.icon.length > 0 ? Quickshell.iconPath(app.icon, "") : ""

  height: 58

  Style {
    id: style
  }

  Rectangle {
    anchors.fill: parent
    color: row.selected ? style.accent : (mouseArea.containsMouse ? style.backgroundAlt : "transparent")
    border.color: row.selected ? style.accent : style.border
    border.width: row.selected || mouseArea.containsMouse ? 1 : 0
  }

  IconImage {
    id: appIcon

    anchors.left: parent.left
    anchors.leftMargin: 10
    anchors.verticalCenter: parent.verticalCenter
    width: 32
    height: 32
    source: row.iconSource
    implicitSize: 32
    asynchronous: true
    mipmap: true
    visible: row.iconSource.length > 0
  }

  Rectangle {
    anchors.fill: appIcon
    visible: row.iconSource.length === 0
    color: style.backgroundAlt
    border.color: row.selected ? style.selectedForeground : style.border
    border.width: 1

    Text {
      anchors.centerIn: parent
      text: row.appName.length > 0 ? row.appName[0].toUpperCase() : "?"
      color: row.selected ? style.selectedForeground : style.foreground
      font.family: style.fontFamily
      font.pixelSize: 15
      font.bold: true
    }
  }

  Text {
    id: nameLabel

    anchors.left: appIcon.right
    anchors.leftMargin: 12
    anchors.right: parent.right
    anchors.rightMargin: 12
    anchors.top: parent.top
    anchors.topMargin: 9
    text: row.appName
    color: row.selected ? style.selectedForeground : style.foreground
    font.family: style.fontFamily
    font.pixelSize: 14
    elide: Text.ElideRight
  }

  Text {
    anchors.left: nameLabel.left
    anchors.right: nameLabel.right
    anchors.top: nameLabel.bottom
    anchors.topMargin: 4
    text: row.description
    color: row.selected ? style.selectedForeground : style.muted
    font.family: style.fontFamily
    font.pixelSize: 12
    elide: Text.ElideRight
  }

  MouseArea {
    id: mouseArea

    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: row.clicked()
  }
}
