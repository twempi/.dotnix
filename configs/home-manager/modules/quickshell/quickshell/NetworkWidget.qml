import Quickshell.Services.NetworkManager
import QtQuick

Item {
    id: root
    implicitWidth: 34
    implicitHeight: 36

    property var activeConnection: NetworkManager.primaryConnection
    property bool wifi: activeConnection?.type === NetworkManager.Wifi
    property bool ethernet: activeConnection?.type === NetworkManager.Ethernet
    property bool connected: activeConnection !== null
    property int strength: wifi ? (NetworkManager.wifiDevice?.activeAccessPoint?.strength ?? 0) : 100

    Rectangle {
        anchors.centerIn: parent
        width: 28
        height: 28
        radius: 8
        color: netHover.hovered ? "#2289b4fa" : "#11cdd6f4"
        Behavior on color { ColorAnimation { duration: 120 } }

        HoverHandler { id: netHover }

        Text {
            anchors.centerIn: parent
            text: {
                if (!root.connected) return "󰤭"
                if (root.ethernet)  return "󰈀"
                const s = root.strength
                if (s >= 80) return "󰤨"
                if (s >= 60) return "󰤥"
                if (s >= 40) return "󰤢"
                if (s >= 20) return "󰤟"
                return "󰤯"
            }
            font.pixelSize: 14
            font.family: "Symbols Nerd Font"
            color: root.connected ? "#a6e3a1" : "#f38ba8"
        }

        ToolTip.visible: netHover.hovered
        ToolTip.text: root.connected
            ? (root.wifi
                ? `${NetworkManager.wifiDevice?.activeAccessPoint?.ssid ?? "WiFi"} · ${root.strength}%`
                : "Ethernet")
            : "Disconnected"
        ToolTip.delay: 400
    }
}
