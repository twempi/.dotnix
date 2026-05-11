import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

ShellRoot {
  id: root

  property var wallpapers: []
  property string query: ""
  property int selectedIndex: 0
  property string statusText: listProcess.running ? "Loading wallpapers" : (wallpapers.length + " wallpapers")
  property string errorText: ""
  readonly property string targetScreenName: Quickshell.env("QS_WALLPAPER_SCREEN") || ""
  readonly property var filteredWallpapers: wallpapers.filter(function(wallpaper) {
    return root.query.length === 0 || wallpaper.name.toLowerCase().indexOf(root.query.toLowerCase()) !== -1;
  })

  function targetScreen() {
    if (root.targetScreenName.length > 0) {
      for (var i = 0; i < Quickshell.screens.length; i++) {
        if (Quickshell.screens[i].name === root.targetScreenName) {
          return Quickshell.screens[i];
        }
      }
    }

    return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null;
  }

  function parseWallpaperPayload(output) {
    try {
      var payload = JSON.parse(output);
      var parsed = payload.wallpapers || [];

      root.wallpapers = parsed;
      root.selectedIndex = parsed.length > 0 ? 0 : -1;
      root.errorText = payload.ok === false ? (payload.error || "Could not read wallpapers") : "";
    } catch (error) {
      root.wallpapers = [];
      root.selectedIndex = -1;
      root.errorText = "Could not parse wallpaper list";
    }
  }

  function clampSelection() {
    if (filteredWallpapers.length === 0) {
      selectedIndex = -1;
    } else if (selectedIndex < 0) {
      selectedIndex = 0;
    } else if (selectedIndex >= filteredWallpapers.length) {
      selectedIndex = filteredWallpapers.length - 1;
    }
  }

  function moveSelection(delta) {
    if (filteredWallpapers.length === 0 || applyProcess.running) {
      return;
    }

    selectedIndex = Math.max(0, Math.min(filteredWallpapers.length - 1, selectedIndex + delta));
    grid.positionViewAtIndex(selectedIndex, GridView.Contain);
  }

  function applySelected() {
    applyWallpaper(selectedIndex);
  }

  function applyWallpaper(index) {
    if (index < 0 || index >= filteredWallpapers.length || applyProcess.running) {
      return;
    }

    selectedIndex = index;
    var wallpaper = filteredWallpapers[index];
    applyProcess.pendingPath = wallpaper.path;
    applyProcess.lastError = "";
    root.errorText = "";
    root.statusText = "Applying " + wallpaper.name;
    applyProcess.command = ["qs-wallpaper-apply", wallpaper.path];
    applyProcess.running = true;
  }

  function handleKey(event) {
    if (event.key === Qt.Key_Escape) {
      Qt.quit();
      event.accepted = true;
    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
      root.applySelected();
      event.accepted = true;
    } else if (event.key === Qt.Key_Down) {
      root.moveSelection(grid.columnCount);
      event.accepted = true;
    } else if (event.key === Qt.Key_Up) {
      root.moveSelection(-grid.columnCount);
      event.accepted = true;
    } else if (event.key === Qt.Key_Right) {
      root.moveSelection(1);
      event.accepted = true;
    } else if (event.key === Qt.Key_Left) {
      root.moveSelection(-1);
      event.accepted = true;
    }
  }

  function emptyText() {
    if (listProcess.running) {
      return "";
    }
    if (errorText.length > 0 && wallpapers.length === 0) {
      return errorText;
    }
    if (wallpapers.length === 0) {
      return "No wallpapers found";
    }
    return "No matches";
  }

  onFilteredWallpapersChanged: clampSelection()

  Component.onCompleted: {
    listProcess.running = true;
  }

  Style {
    id: style
  }

  Process {
    id: listProcess

    command: ["qs-wallpaper-list"]

    stdout: StdioCollector {
      onStreamFinished: root.parseWallpaperPayload(this.text)
    }

    stderr: StdioCollector {
      onStreamFinished: {
        if (this.text.length > 0) {
          root.errorText = this.text.trim();
        }
      }
    }

    onExited: function(exitCode, exitStatus) {
      if (exitCode !== 0 && root.wallpapers.length === 0 && root.errorText.length === 0) {
        root.errorText = "Could not list wallpapers";
      }
    }
  }

  Process {
    id: applyProcess

    property string pendingPath: ""
    property string lastError: ""

    stderr: StdioCollector {
      onStreamFinished: applyProcess.lastError = this.text.trim()
    }

    onExited: function(exitCode, exitStatus) {
      if (exitCode === 0) {
        Qt.quit();
      } else {
        root.statusText = root.wallpapers.length + " wallpapers";
        root.errorText = applyProcess.lastError.length > 0 ? applyProcess.lastError : "Failed to apply wallpaper";
        searchInput.forceActiveFocus();
      }
    }
  }

  PanelWindow {
    id: overlayWindow

    screen: root.targetScreen()
    color: "transparent"
    surfaceFormat.opaque: false
    exclusionMode: ExclusionMode.Ignore

    anchors {
      left: true
      right: true
      top: true
      bottom: true
    }

    WlrLayershell.namespace: "qs-wallpaper"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    Component.onCompleted: {
      overlayFocus.forceActiveFocus();
      searchInput.forceActiveFocus();
    }

    Item {
      id: overlayFocus

      anchors.fill: parent
      focus: true

      Keys.onPressed: function(event) {
        root.handleKey(event);
      }

      Rectangle {
        anchors.fill: parent
        color: "#99000000"
      }

      MouseArea {
        anchors.fill: parent
        onPressed: searchInput.forceActiveFocus()
      }

      Rectangle {
        id: panel

        width: parent.width >= 740 ? Math.min(1000, parent.width - 40) : Math.max(1, parent.width - 24)
        height: parent.height >= 460 ? Math.min(600, parent.height - 40) : Math.max(1, parent.height - 24)
        anchors.centerIn: parent
        color: style.background
        border.color: style.border
        border.width: 1
        clip: true

        Item {
          id: content

          anchors.fill: parent
          anchors.margins: 14

          Rectangle {
            id: searchBox

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: countLabel.left
            anchors.rightMargin: 12
            height: 42
            color: style.backgroundAlt
            border.color: searchInput.activeFocus ? style.accent : style.border
            border.width: 1

            Text {
              anchors.left: parent.left
              anchors.leftMargin: 12
              anchors.verticalCenter: parent.verticalCenter
              visible: searchInput.text.length === 0
              text: "Search wallpapers"
              color: style.muted
              font.family: style.fontFamily
              font.pixelSize: 14
            }

            TextInput {
              id: searchInput

              anchors.fill: parent
              anchors.leftMargin: 12
              anchors.rightMargin: 12
              color: style.foreground
              selectionColor: style.accent
              selectedTextColor: style.selectedForeground
              clip: true
              font.family: style.fontFamily
              font.pixelSize: 14
              verticalAlignment: TextInput.AlignVCenter
              focus: true

              onTextChanged: {
                root.query = text;
                root.selectedIndex = root.filteredWallpapers.length > 0 ? 0 : -1;
                if (root.selectedIndex >= 0) {
                  grid.positionViewAtIndex(root.selectedIndex, GridView.Beginning);
                }
              }

              Keys.onPressed: function(event) {
                root.handleKey(event);
              }
            }
          }

          Text {
            id: countLabel

            anchors.top: searchBox.top
            anchors.right: parent.right
            width: 150
            height: searchBox.height
            text: applyProcess.running ? "Applying" : (root.filteredWallpapers.length + " / " + root.wallpapers.length)
            color: applyProcess.running ? style.accent : style.muted
            font.family: style.fontFamily
            font.pixelSize: 13
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
          }

          GridView {
            id: grid

            property int columnCount: Math.max(2, Math.floor(width / 155))

            anchors.top: searchBox.bottom
            anchors.topMargin: 12
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: statusLine.top
            anchors.bottomMargin: 10
            clip: true
            model: root.filteredWallpapers
            currentIndex: root.selectedIndex
            cellWidth: width / columnCount
            cellHeight: 142
            boundsBehavior: Flickable.StopAtBounds
            keyNavigationEnabled: false
            highlightMoveDuration: 80

            delegate: WallpaperCard {
              width: grid.cellWidth - 8
              height: grid.cellHeight - 8
              fileName: modelData.name
              imageSource: modelData.thumbUrl
              selected: index === root.selectedIndex
              busy: applyProcess.running && applyProcess.pendingPath === modelData.path

              onClicked: root.applyWallpaper(index)
            }
          }

          Text {
            anchors.centerIn: grid
            width: grid.width - 40
            visible: !listProcess.running && root.filteredWallpapers.length === 0
            text: root.emptyText()
            color: root.errorText.length > 0 ? style.urgent : style.muted
            font.family: style.fontFamily
            font.pixelSize: 14
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
          }

          Text {
            id: statusLine

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            height: 20
            text: root.errorText.length > 0 ? root.errorText : root.statusText
            color: root.errorText.length > 0 ? style.urgent : style.muted
            font.family: style.fontFamily
            font.pixelSize: 12
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
          }
        }
      }
    }
  }
}
