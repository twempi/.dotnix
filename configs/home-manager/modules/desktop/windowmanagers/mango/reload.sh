#!/usr/bin/env bash
set -euo pipefail

pkill waybar
pkill -x rofi 2>/dev/null || true

mmsg dispatch reload_config

waybar -c ~/.config/waybar/mango.jsonc -s ~/.config/waybar/mango.css &

systemctl --user restart swaync.service 2>/dev/null || {
  pkill swaync 2>/dev/null || true
  swaync >/dev/null 2>&1 &
}
