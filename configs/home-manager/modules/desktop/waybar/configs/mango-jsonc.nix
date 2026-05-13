{config, ...}: {
  xdg.configFile."waybar/mango.jsonc".text = ''
    {
      "name": "mango",

      "layer": "top",
      "height": 20,
      "spacing": 4,
      "margin-top": 0,
      "margin-right": 0,
      "margin-left": 0,

      "modules-left": [
        "dwl/tags",
        "dwl/window"
      ],

      "modules-right": [
        "tray",
        "network",
        "disk",
        "cpu",
        // "custom/cpu_temp",
        "backlight",
        "custom/memory",
        "pulseaudio",
        "battery",
        "clock"
      ],

      // MangoWC / DWL tags
      "dwl/tags": {
        "num-tags": 9,
        "tag-labels": [
          "1",
          "2",
          "3",
          "4",
          "5",
          "6",
          "7",
          "8",
          "9"
        ],
        "disable-click": false
      },

      // Focused window title
      "dwl/window": {
        "format": "{title}",
        "max-length": 80,
        "tooltip": false
      },

      "tray": {
        "icon-size": 14,
        "spacing": 8
      },

      "disk": {
        "format": "<span color='#${config.lib.stylix.colors.base08}'>[]</span> {free}",
        "interval": 20
      },

      "cpu": {
        "format": "<span color='#${config.lib.stylix.colors.base09}'>[]</span> {usage}%",
        "tooltip": false,
        "interval": 1
      },

      "custom/cpu_temp": {
        "exec": "~/.config/waybar/scripts/waybarTemp.sh",
        "return-type": "json",
        "interval": 2,
        "format": "{}",
        "tooltip": false
      },

      "backlight": {
        // "device": "acpi_video1",
        "format": "<span color='#${config.lib.stylix.colors.base0A}'>[󰞏]</span> {percent}%",
        "tooltip": false,
        "on-click-right": "~/.config/waybar/scripts/wlsunset.sh"
      },

      "custom/memory": {
        "exec": "~/.config/waybar/scripts/memory_usage.sh",
        "interval": 2,
        "return-type": "json",
        "format": "<span color='#${config.lib.stylix.colors.base0C}'>[]</span> {}"
      },

      "pulseaudio": {
        // "scroll-step": 1,
        "format": "<span color='#${config.lib.stylix.colors.base0D}'>[]</span> {volume}%",
        "format-muted": "<span color='#${config.lib.stylix.colors.base08}'>[]</span> {volume}%",
        "format-bluetooth": "<span color='#${config.lib.stylix.colors.base0D}'>[󰂰]</span> {volume}%",
        "format-bluetooth-muted": "<span color='#${config.lib.stylix.colors.base08}'>[󰂲]</span> {volume}%",
        "format-source": "{volume}% ",
        "on-click": "pactl set-sink-mute @DEFAULT_SINK@ toggle",
        "on-click-right": "pulseaudio",
        "tooltip": false,
        "max-volume": 130
      },

      "battery#bat2": {
        "bat": "BAT2"
      },

      "battery": {
        "interval": 1,
        "states": {
          "good": 99,
          "warning": 30,
          "critical": 20
        },
        "format-icons": [
          "󰂎",
          "󰁺",
          "󰁻",
          "󰁽",
          "󰁾",
          "󰁿",
          "󰂀",
          "󰂁",
          "󰂂",
          "󰁹"
        ],

        "format": "<span color='#${config.lib.stylix.colors.base0B}'>[{icon}]</span> {capacity}%",
        "format-full": "<span color='#${config.lib.stylix.colors.base0B}'>[{icon}]</span> {capacity}%",
        "format-plugged": "<span color='#${config.lib.stylix.colors.base0B}'>[󰂅]</span> {capacity}%",

        "format-charging": "<span color='#${config.lib.stylix.colors.base0B}'>[󰂅]</span> {capacity}%",
        "format-charging-warning": "<span color='#${config.lib.stylix.colors.base09}'>[󰢝]</span> {capacity}%",
        "format-charging-critical": "<span color='#${config.lib.stylix.colors.base08}'>[󰢜]</span> {capacity}%",

        "format-warning": "<span color='#${config.lib.stylix.colors.base09}'>[{icon}]</span> {capacity}%",
        "format-critical": "<span color='#${config.lib.stylix.colors.base08}'>[{icon}]</span> {capacity}%!!",

        "format-alt": "<span color='#${config.lib.stylix.colors.base0B}'>[󱧥]</span> {time}",

        "tooltip": false
      },

      "clock": {
        "format": "<span color='#${config.lib.stylix.colors.base0A}'>[]</span> {:%a %d | %I:%M %p}",
        "tooltip": false,
        "on-click": "swaync-client -t -sw",
        "escape": true,
        "interval": 1
      },

      "network": {
        "interval": 2,
        "format": "<span color='#${config.lib.stylix.colors.base0E}'>[󱘖]</span> {bandwidthDownBits}",
        "format-wifi": "<span color='#${config.lib.stylix.colors.base0E}'>[{icon}]</span> {bandwidthDownBits}",
        "format-ethernet": "<span color='#${config.lib.stylix.colors.base0E}'>[󰈀]</span> {bandwidthDownBits}",
        "format-icons": [
          "󰤫",
          "󰤟",
          "󰤢",
          "󰤥",
          "󰤨"
        ],
        "tooltip": false,
        "states": {
          "normal": 25
        }
      }
    }
  '';
}
