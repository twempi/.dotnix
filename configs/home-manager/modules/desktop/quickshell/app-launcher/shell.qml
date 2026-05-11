import Quickshell
import Quickshell.Wayland
import QtQuick

ShellRoot {
  id: root

  property string query: ""
  property int selectedIndex: 0
  readonly property string targetScreenName: Quickshell.env("QS_TARGET_SCREEN") || ""
  readonly property var apps: DesktopEntries.applications.values
  readonly property var filteredApps: [...apps].filter(function(app) {
    var text = appSearchText(app);
    return root.query.length === 0 || text.indexOf(root.query.toLowerCase()) !== -1;
  }).sort(compareApps)

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

  function listText(value) {
    if (!value) {
      return "";
    }
    if (value.join) {
      return value.join(" ");
    }
    return String(value);
  }

  function appSearchText(app) {
    return [
      app.name || "",
      app.genericName || "",
      app.comment || "",
      app.id || "",
      listText(app.categories),
      listText(app.keywords),
    ].join(" ").toLowerCase();
  }

  function compareApps(left, right) {
    var a = (left.name || left.id || "").toLowerCase();
    var b = (right.name || right.id || "").toLowerCase();
    if (a < b) {
      return -1;
    }
    if (a > b) {
      return 1;
    }
    return 0;
  }

  function clampSelection() {
    if (filteredApps.length === 0) {
      selectedIndex = -1;
    } else if (selectedIndex < 0) {
      selectedIndex = 0;
    } else if (selectedIndex >= filteredApps.length) {
      selectedIndex = filteredApps.length - 1;
    }
  }

  function moveSelection(delta) {
    if (filteredApps.length === 0) {
      return;
    }

    selectedIndex = Math.max(0, Math.min(filteredApps.length - 1, selectedIndex + delta));
    list.positionViewAtIndex(selectedIndex, ListView.Contain);
  }

  function launchApp(index) {
    if (index < 0 || index >= filteredApps.length) {
      return;
    }

    filteredApps[index].execute();
    Qt.quit();
  }

  function handleKey(event) {
    if (event.key === Qt.Key_Escape) {
      Qt.quit();
      event.accepted = true;
    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
      launchApp(selectedIndex);
      event.accepted = true;
    } else if (event.key === Qt.Key_Down) {
      moveSelection(1);
      event.accepted = true;
    } else if (event.key === Qt.Key_Up) {
      moveSelection(-1);
      event.accepted = true;
    } else if (event.key === Qt.Key_PageDown) {
      moveSelection(7);
      event.accepted = true;
    } else if (event.key === Qt.Key_PageUp) {
      moveSelection(-7);
      event.accepted = true;
    }
  }

  onFilteredAppsChanged: clampSelection()

  Style {
    id: style
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

    WlrLayershell.namespace: "qs-launcher"
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

        width: parent.width >= 680 ? Math.min(640, parent.width - 40) : Math.max(1, parent.width - 24)
        height: parent.height >= 560 ? Math.min(520, parent.height - 40) : Math.max(1, parent.height - 24)
        anchors.centerIn: parent
        color: style.background
        border.color: style.border
        border.width: 1
        clip: true

        Item {
          anchors.fill: parent
          anchors.margins: 12

          Rectangle {
            id: searchBox

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: countLabel.left
            anchors.rightMargin: 10
            height: 42
            color: style.backgroundAlt
            border.color: searchInput.activeFocus ? style.accent : style.border
            border.width: 1

            Text {
              anchors.left: parent.left
              anchors.leftMargin: 12
              anchors.verticalCenter: parent.verticalCenter
              visible: searchInput.text.length === 0
              text: "Search applications"
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
                root.selectedIndex = root.filteredApps.length > 0 ? 0 : -1;
                if (root.selectedIndex >= 0) {
                  list.positionViewAtIndex(root.selectedIndex, ListView.Beginning);
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
            width: 90
            height: searchBox.height
            text: root.filteredApps.length + " / " + root.apps.length
            color: style.muted
            font.family: style.fontFamily
            font.pixelSize: 12
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
          }

          ListView {
            id: list

            anchors.top: searchBox.bottom
            anchors.topMargin: 10
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: statusLine.top
            anchors.bottomMargin: 8
            clip: true
            spacing: 5
            model: root.filteredApps
            currentIndex: root.selectedIndex
            boundsBehavior: Flickable.StopAtBounds
            keyNavigationEnabled: false
            highlightMoveDuration: 80

            delegate: AppRow {
              width: list.width
              app: modelData
              selected: index === root.selectedIndex
              onClicked: root.launchApp(index)
            }
          }

          Text {
            anchors.centerIn: list
            width: list.width - 40
            visible: root.filteredApps.length === 0
            text: root.apps.length === 0 ? "No applications found" : "No matches"
            color: style.muted
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
            height: 18
            text: "Applications"
            color: style.muted
            font.family: style.fontFamily
            font.pixelSize: 12
            verticalAlignment: Text.AlignVCenter
          }
        }
      }
    }
  }
}
