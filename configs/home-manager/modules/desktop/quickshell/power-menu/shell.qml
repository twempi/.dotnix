import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick

ShellRoot {
  id: root

  property int selectedIndex: 0
  property string host: "Power"
  property string uptime: "unknown"
  readonly property string targetScreenName: Quickshell.env("QS_TARGET_SCREEN") || ""
  readonly property var actions: [
    {"name": "Lock", "label": "Lock", "icon": "./icons/lock.svg", "action": "lock", "shortcut": ""},
    {"name": "Suspend", "label": "Suspend", "icon": "./icons/suspend.svg", "action": "suspend", "shortcut": "S"},
    {"name": "Logout", "label": "Logout", "icon": "./icons/logout.svg", "action": "logout", "shortcut": "L"},
    {"name": "Reboot", "label": "Reboot", "icon": "./icons/reboot.svg", "action": "reboot", "shortcut": "R"},
    {"name": "Shutdown", "label": "Shutdown", "icon": "./icons/shutdown.svg", "action": "shutdown", "shortcut": "P"},
  ]

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

  function parseInfo(output) {
    try {
      var payload = JSON.parse(output);
      root.host = payload.host || "Power";
      root.uptime = payload.uptime || "unknown";
    } catch (error) {
      root.host = "Power";
      root.uptime = "unknown";
    }
  }

  function moveSelection(delta) {
    selectedIndex = Math.max(0, Math.min(actions.length - 1, selectedIndex + delta));
  }

  function runAction(action) {
    Quickshell.execDetached(["qs-power-action", action]);
    Qt.quit();
  }

  function runSelected() {
    runAction(actions[selectedIndex].action);
  }

  function handleKey(event) {
    var keyText = event.text.toLowerCase();

    if (event.key === Qt.Key_Escape) {
      Qt.quit();
      event.accepted = true;
    } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
      runSelected();
      event.accepted = true;
    } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Right) {
      moveSelection(1);
      event.accepted = true;
    } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Left) {
      moveSelection(-1);
      event.accepted = true;
    } else if (keyText === "p") {
      runAction("shutdown");
      event.accepted = true;
    } else if (keyText === "r") {
      runAction("reboot");
      event.accepted = true;
    } else if (keyText === "s") {
      runAction("suspend");
      event.accepted = true;
    } else if (keyText === "l") {
      runAction("logout");
      event.accepted = true;
    }
  }

  Component.onCompleted: infoProcess.running = true

  Style {
    id: theme
  }

  Process {
    id: infoProcess

    command: ["qs-power-info"]

    stdout: StdioCollector {
      onStreamFinished: root.parseInfo(this.text)
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

    WlrLayershell.namespace: "qs-power"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    Component.onCompleted: overlayFocus.forceActiveFocus()

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
        onPressed: overlayFocus.forceActiveFocus()
      }

      Rectangle {
        id: panel

        width: parent.width >= 390 ? 350 : Math.max(1, parent.width - 24)
        height: parent.height >= 430 ? 390 : Math.max(1, parent.height - 24)
        anchors.centerIn: parent
        color: theme.background
        border.color: theme.border
        border.width: 1
        clip: true

        Item {
          anchors.fill: parent
          anchors.margins: 12

          Rectangle {
            id: titleBlock

            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 78
            color: theme.backgroundAlt
            border.color: theme.border
            border.width: 1

            Rectangle {
              id: powerIcon

              anchors.left: parent.left
              anchors.leftMargin: 12
              anchors.verticalCenter: parent.verticalCenter
              width: 42
              height: 42
              color: theme.urgent

              Text {
                anchors.centerIn: parent
                text: "Power"
                color: theme.selectedForeground
                font.family: theme.fontFamily
                font.pixelSize: 10
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
              }
            }

            Text {
              id: hostLabel

              anchors.left: powerIcon.right
              anchors.leftMargin: 12
              anchors.right: parent.right
              anchors.rightMargin: 12
              anchors.top: parent.top
              anchors.topMargin: 15
              text: root.host
              color: theme.foreground
              font.family: theme.fontFamily
              font.pixelSize: 15
              elide: Text.ElideRight
            }

            Text {
              anchors.left: hostLabel.left
              anchors.right: hostLabel.right
              anchors.top: hostLabel.bottom
              anchors.topMargin: 6
              text: "Uptime: " + root.uptime
              color: theme.muted
              font.family: theme.fontFamily
              font.pixelSize: 12
              elide: Text.ElideRight
            }
          }

          ListView {
            id: list

            anchors.top: titleBlock.bottom
            anchors.topMargin: 10
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            clip: true
            spacing: 5
            model: root.actions
            currentIndex: root.selectedIndex
            interactive: false

            delegate: Item {
              width: list.width
              height: 52

              Rectangle {
                anchors.fill: parent
                color: index === root.selectedIndex ? theme.accent : (actionMouse.containsMouse ? theme.backgroundAlt : "transparent")
                border.color: index === root.selectedIndex ? theme.accent : theme.border
                border.width: index === root.selectedIndex || actionMouse.containsMouse ? 1 : 0
              }

              // Text {
              //   id: actionIcon
              //
              //   anchors.left: parent.left
              //   anchors.leftMargin: 12
              //   anchors.verticalCenter: parent.verticalCenter
              //   width: 74
              //   text: modelData.icon
              //   color: index === root.selectedIndex ? theme.selectedForeground : theme.foreground
              //   font.family: theme.fontFamily
              //   font.pixelSize: 12
              //   elide: Text.ElideRight
              // }

              Item {
                id: actionIcon

                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                width: 74
                height: parent.height

                IconImage {
                  anchors.left: parent.left
                  anchors.verticalCenter: parent.verticalCenter
                  implicitSize: 18
                  source: modelData.icon
                }
              }

              Text {
                anchors.left: actionIcon.right
                anchors.right: shortcutLabel.left
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                text: modelData.label
                color: index === root.selectedIndex ? theme.selectedForeground : theme.foreground
                font.family: theme.fontFamily
                font.pixelSize: 14
                elide: Text.ElideRight
              }

              Text {
                id: shortcutLabel

                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                width: 32
                text: modelData.shortcut
                color: index === root.selectedIndex ? theme.selectedForeground : theme.muted
                font.family: theme.fontFamily
                font.pixelSize: 12
                horizontalAlignment: Text.AlignRight
              }

              MouseArea {
                id: actionMouse

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.runAction(modelData.action)
                onEntered: root.selectedIndex = index
              }
            }
          }
        }
      }
    }
  }
}
