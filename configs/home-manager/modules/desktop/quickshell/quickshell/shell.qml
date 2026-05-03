import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Services.NetworkManager
import QtQuick
import QtQuick.Layouts

ShellRoot {
    Variants {
        model: Quickshell.screens
        PanelWindow {
            property var modelData

            screen: modelData
            anchors {
                top: true
                left: true
                right: true
            }
            height: 36
            color: "transparent"
            exclusionMode: ExclusionMode.Exclusive

            Rectangle {
                anchors.fill: parent
                color: "#ee1a1a2e"
                border.color: "#33cdd6f4"
                border.width: 1

                // Subtle bottom glow line
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: "#4489b4fa"
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    spacing: 0

                    // ── LEFT: Workspaces ──────────────────────────────────
                    WorkspacesWidget {
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft
                        Layout.preferredWidth: implicitWidth
                    }

                    Item { Layout.fillWidth: true }

                    // ── CENTER: Clock ─────────────────────────────────────
                    ClockWidget {
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignHCenter
                    }

                    Item { Layout.fillWidth: true }

                    // ── RIGHT: Tray ───────────────────────────────────────
                    SystemTrayWidget {
                        Layout.alignment: Qt.AlignVCenter | Qt.AlignRight
                    }
                }
            }
        }
    }
}
