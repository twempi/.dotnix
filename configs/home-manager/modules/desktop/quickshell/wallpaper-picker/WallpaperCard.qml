import QtQuick

Item {
  id: card

  property string fileName: ""
  property string imageSource: ""
  property bool selected: false
  property bool busy: false

  signal clicked()

  Style {
    id: style
  }

  Rectangle {
    anchors.fill: parent
    color: card.selected ? style.accent : (mouseArea.containsMouse ? style.backgroundAlt : "transparent")
    border.color: card.selected ? style.accent : style.border
    border.width: card.selected || mouseArea.containsMouse ? 1 : 0
  }

  Rectangle {
    id: previewFrame

    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: label.top
    anchors.margins: 6
    anchors.bottomMargin: 5
    color: style.backgroundAlt
    clip: true

    Image {
      id: preview

      anchors.fill: parent
      source: card.imageSource
      asynchronous: false
      cache: true
      fillMode: Image.PreserveAspectCrop
      sourceSize.width: 420
      sourceSize.height: 280
    }

    Rectangle {
      anchors.fill: parent
      visible: card.busy
      color: "#99000000"
    }

    Text {
      anchors.centerIn: parent
      visible: card.busy
      text: "Applying"
      color: style.foreground
      font.family: style.fontFamily
      font.pixelSize: 12
    }

    Text {
      anchors.centerIn: parent
      width: parent.width - 20
      visible: preview.status === Image.Error
      text: "Preview unavailable"
      color: style.muted
      font.family: style.fontFamily
      font.pixelSize: 12
      horizontalAlignment: Text.AlignHCenter
      wrapMode: Text.Wrap
    }
  }

  Text {
    id: label

    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.leftMargin: 6
    anchors.rightMargin: 6
    anchors.bottomMargin: 7
    height: 18
    text: card.fileName
    color: card.selected ? style.selectedForeground : style.foreground
    font.family: style.fontFamily
    font.pixelSize: 12
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
    elide: Text.ElideMiddle
  }

  MouseArea {
    id: mouseArea

    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: card.clicked()
  }
}
