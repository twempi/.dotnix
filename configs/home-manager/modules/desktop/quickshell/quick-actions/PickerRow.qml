import QtQuick

Item {
  id: row

  property string variant: "clipboard"
  property string label: ""
  property string description: ""
  property bool selected: false

  signal clicked()

  height: variant === "emoji" ? 58 : 54

  Style {
    id: style
  }

  Rectangle {
    anchors.fill: parent
    color: row.selected ? style.accent : (mouseArea.containsMouse ? style.backgroundAlt : "transparent")
    border.color: row.selected ? style.accent : style.border
    border.width: row.selected || mouseArea.containsMouse ? 1 : 0
  }

  Text {
    id: emojiLabel

    anchors.left: parent.left
    anchors.leftMargin: 12
    anchors.verticalCenter: parent.verticalCenter
    width: row.variant === "emoji" ? 44 : 0
    visible: row.variant === "emoji"
    text: row.label
    color: row.selected ? style.selectedForeground : style.foreground
    font.family: style.fontFamily
    font.pixelSize: 24
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    elide: Text.ElideRight
  }

  Text {
    id: labelText

    anchors.left: row.variant === "emoji" ? emojiLabel.right : parent.left
    anchors.leftMargin: row.variant === "emoji" ? 12 : 12
    anchors.right: parent.right
    anchors.rightMargin: 12
    anchors.top: parent.top
    anchors.topMargin: row.variant === "emoji" ? 10 : 8
    text: row.variant === "emoji" ? row.description : row.label
    color: row.selected ? style.selectedForeground : style.foreground
    font.family: style.fontFamily
    font.pixelSize: row.variant === "emoji" ? 14 : 13
    elide: Text.ElideRight
  }

  Text {
    anchors.left: labelText.left
    anchors.right: labelText.right
    anchors.top: labelText.bottom
    anchors.topMargin: 4
    text: row.variant === "emoji" ? row.label : row.description
    color: row.selected ? style.selectedForeground : style.muted
    font.family: style.fontFamily
    font.pixelSize: 11
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
