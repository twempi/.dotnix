import Quickshell
import Quickshell.Io
import Quickshell.Services.SystemTray
import Quickshell.Wayland
import QtQuick

ShellRoot {
  id: root

  Style {
    id: theme
  }

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: bar

      property var modelData
      property var tags: defaultTags()
      property string audioText: "VOL --"
      property string backlightText: ""
      property string batteryText: ""
      property bool batteryVisible: false
      property string notificationText: "NOTI"

      screen: modelData
      color: "transparent"
      surfaceFormat.opaque: false
      implicitHeight: 28
      exclusionMode: ExclusionMode.Auto

      anchors {
        left: true
        right: true
        top: true
      }

      margins {
        left: 5
        right: 5
        top: 5
      }

      WlrLayershell.namespace: "qs-top-bar"
      WlrLayershell.layer: WlrLayer.Top

      function defaultTags() {
        var values = [];
        for (var i = 1; i <= 10; i++) {
          values.push({"id": i, "name": String(i), "active": false, "occupied": false, "urgent": false});
        }
        return values;
      }

      function refreshProcess(process) {
        if (!process.running) {
          process.running = true;
        }
      }

      function parseTags(output) {
        try {
          var payload = JSON.parse(output);
          bar.tags = payload.tags || bar.defaultTags();
        } catch (error) {
          bar.tags = bar.defaultTags();
        }
      }

      function parseAudio(output) {
        try {
          var payload = JSON.parse(output);
          bar.audioText = payload.text || "VOL --";
        } catch (error) {
          bar.audioText = "VOL --";
        }
      }

      function parseBacklight(output) {
        try {
          var payload = JSON.parse(output);
          bar.backlightText = payload.text || "";
        } catch (error) {
          bar.backlightText = "";
        }
      }

      function parseBattery(output) {
        try {
          var payload = JSON.parse(output);
          bar.batteryVisible = payload.visible === true;
          bar.batteryText = payload.text || "";
        } catch (error) {
          bar.batteryVisible = false;
          bar.batteryText = "";
        }
      }

      function parseNotification(output) {
        try {
          var payload = JSON.parse(output);
          bar.notificationText = payload.text || "NOTI";
        } catch (error) {
          bar.notificationText = "NOTI";
        }
      }

      Rectangle {
        anchors.fill: parent
        color: theme.background
        border.color: theme.border
        border.width: 2
      }

      Row {
        id: tagRow

        anchors.left: parent.left
        anchors.leftMargin: 15
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height
        spacing: 2

        Repeater {
          model: bar.tags

          delegate: Rectangle {
            width: modelData.id === 10 ? 24 : 18
            height: tagRow.height
            color: "transparent"

            Text {
              anchors.centerIn: parent
              text: modelData.name
              color: modelData.urgent ? theme.urgent : (modelData.occupied || modelData.active ? theme.foreground : theme.muted)
              font.family: theme.fontFamily
              font.pixelSize: 12
              font.bold: true
            }

            Rectangle {
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.bottom: parent.bottom
              anchors.leftMargin: 4
              anchors.rightMargin: 4
              height: 2
              visible: modelData.active || modelData.urgent
              color: modelData.urgent ? theme.urgent : theme.accent
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: Quickshell.execDetached(["qs-mango-tag", String(modelData.id)])
            }
          }
        }
      }

      Text {
        anchors.centerIn: parent
        text: Qt.formatDateTime(clock.date, "MM/dd hh:mm")
        color: theme.foreground
        font.family: theme.fontFamily
        font.pixelSize: 12
        font.bold: true
      }

      Row {
        id: rightModules

        anchors.right: parent.right
        anchors.rightMargin: 15
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height
        spacing: 6

        Row {
          id: trayRow

          anchors.verticalCenter: parent.verticalCenter
          height: parent.height
          spacing: 5
          visible: SystemTray.items.values.length > 0

          Repeater {
            model: SystemTray.items

            delegate: Item {
              id: trayIcon

              width: 17
              height: parent.height

              Image {
                anchors.centerIn: parent
                width: 15
                height: 15
                sourceSize.width: 15
                sourceSize.height: 15
                fillMode: Image.PreserveAspectFit
                source: modelData.icon
              }

              MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                cursorShape: Qt.PointingHandCursor
                onClicked: function(mouse) {
                  if (mouse.button === Qt.RightButton && modelData.hasMenu) {
                    modelData.display(bar, trayIcon.x, trayIcon.y + trayIcon.height);
                  } else if (mouse.button === Qt.MiddleButton) {
                    modelData.secondaryActivate();
                  } else {
                    modelData.activate();
                  }
                }
              }
            }
          }
        }

        Text {
          text: "|"
          color: theme.foreground
          font.family: theme.fontFamily
          font.pixelSize: 12
          font.bold: true
        }

        Text {
          visible: bar.backlightText.length > 0
          text: bar.backlightText
          color: theme.foreground
          font.family: theme.fontFamily
          font.pixelSize: 12
          font.bold: true
        }

        Text {
          visible: bar.batteryVisible
          text: bar.batteryText
          color: theme.foreground
          font.family: theme.fontFamily
          font.pixelSize: 12
          font.bold: true
        }

        Text {
          id: audioModule

          text: bar.audioText
          color: theme.foreground
          font.family: theme.fontFamily
          font.pixelSize: 12
          font.bold: true

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: Quickshell.execDetached(["qs-manager", "toggle", "volume"])
          }
        }

        Text {
          text: "|"
          color: theme.foreground
          font.family: theme.fontFamily
          font.pixelSize: 12
          font.bold: true
        }

        Text {
          id: notificationModule

          text: bar.notificationText
          color: theme.foreground
          font.family: theme.fontFamily
          font.pixelSize: 12
          font.bold: true

          MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: function(mouse) {
              if (mouse.button === Qt.RightButton) {
                Quickshell.execDetached(["swaync-client", "-d", "-sw"]);
              } else {
                Quickshell.execDetached(["swaync-client", "-t", "-sw"]);
              }
              bar.refreshProcess(notificationProcess);
            }
          }
        }
      }

      Process {
        id: tagsProcess
        command: ["qs-mango-tags", bar.modelData.name]
        stdout: StdioCollector {
          onStreamFinished: bar.parseTags(this.text)
        }
      }

      Process {
        id: audioProcess
        command: ["qs-audio-status"]
        stdout: StdioCollector {
          onStreamFinished: bar.parseAudio(this.text)
        }
      }

      Process {
        id: backlightProcess
        command: ["qs-backlight-status"]
        stdout: StdioCollector {
          onStreamFinished: bar.parseBacklight(this.text)
        }
      }

      Process {
        id: batteryProcess
        command: ["qs-battery-status"]
        stdout: StdioCollector {
          onStreamFinished: bar.parseBattery(this.text)
        }
      }

      Process {
        id: notificationProcess
        command: ["qs-notification-status"]
        stdout: StdioCollector {
          onStreamFinished: bar.parseNotification(this.text)
        }
      }

      Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
          bar.refreshProcess(tagsProcess);
          bar.refreshProcess(audioProcess);
        }
      }

      Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
          bar.refreshProcess(backlightProcess);
          bar.refreshProcess(batteryProcess);
          bar.refreshProcess(notificationProcess);
        }
      }
    }
  }
}
