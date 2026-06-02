{config, ...}: {
  xdg.configFile."waybar/mango.jsonc".text = ''
    {
      "name": "mango",

      "layer": "top",
      "position": "top",
      "height": 10,
      "spacing": 6,
      "margin-top": 4,
      "margin-right": 4,
      "margin-left": 4,

      "modules-left": [
        "ext/workspaces"
      ],

      "modules-right": [
        "network",
        "backlight",
        "cpu",
        "memory",
        "wireplumber",
        "battery",
        "clock"
      ],

      "ext/workspaces": {
        "format": "{name}",
        "sort-by-id": true,
        "ignore-hidden": true,
        "all-outputs": false,
        "active-only": false,
        "on-click": "activate"
      },

      "dwl/window": {
        "format": "{title}",
        "icon": true,
        "icon-size": 16,
        "swap-icon-label": false,
        "max-length": 70,
        "expand": true,
        "tooltip": false,
        "rewrite": {
          "^$": "Workspace Overview"
        }
      },

      "network": {
        "format-wifi": "{icon} {signalStrength:>2}%",
        "format-ethernet": "󰈀",
        "format-linked": "󰈀",
        "format-disconnected": "󰖪",
        "format-icons": [
          "󰤯",
          "󰤟",
          "󰤢",
          "󰤥",
          "󰤨"
        ],
        "tooltip-format": "{ifname} {ipaddr}/{cidr}",
        "tooltip-format-wifi": "{essid}\\nSignal: {signalStrength}%\\n{ipaddr}/{cidr}"
      },

      "wireplumber": {
        "format": "󰕾 {volume:>2}%",
        "format-muted": "󰝟 muted",
        "format-icons": {
          "default": [
            "󰕿",
            "󰖀",
            "󰕾"
          ]
        },
        "scroll-step": 5,
        "on-click": "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle",
        "tooltip-format": "{node_name} {volume}%"
      },

      "cpu": {
        "format": "󰍛 {usage:>2}%",
        "tooltip": false
      },

      "memory": {
        "format": "󰘚 {}%",
        "tooltip-format": "{used:0.1f}G / {total:0.1f}G"
      },

      "battery": {
        "states": {
          "warning": 30,
          "critical": 15
        },
        "format": "{icon} {capacity:>2}%",
        "format-charging": "󰂄 {capacity:>2}%",
        "format-plugged": "󰂄 {capacity:>2}%",
        "format-full": "󰁹 100%",
        "format-alt": "BAT {time}",
        "format-icons": [
          "󰂎",
          "󰁺",
          "󰁼",
          "󰁾",
          "󰂀",
          "󰁹"
        ],
        "tooltip-format": "{capacity}% {timeTo}\\n{power:0.1f}W"
      },

      "backlight": {
        "format": "󰃠 {percent:>2}%",
        "format-icons": [
          "󰃞",
          "󰃟",
          "󰃠"
        ],
        "tooltip": false,
        "on-scroll-up": "brightnessctl set +5%",
        "on-scroll-down": "brightnessctl set 5%-"
      },

      "clock": {
        "format": "{:%a %d %b  %H:%M}",
        "format-alt": "{:%Y-%m-%d %H:%M}",
        "tooltip-format": "<span weight='bold'>{:%A, %d %B %Y}</span>\\n<tt>{calendar}</tt>",
       // "calendar": {
       //   "mode": "month",
       //   "mode-mon-col": 3,
       //   "weeks-pos": "left",
       //   "on-scroll": 1,
       //   "format": {
       //     "months": "<span weight='bold'>{}</span>",
       //     "days": "{}",
       //     "weeks": "<span color='#${config.lib.stylix.colors.base03}'>W{}</span>",
       //     "weekdays": "<span color='#${config.lib.stylix.colors.base04}'>{}</span>",
       //     "today": "<span background='#${config.lib.stylix.colors.base0A}' color='#${config.lib.stylix.colors.base00}'>{}</span>"
       //   }
       // }
      }
    }
  '';
}
