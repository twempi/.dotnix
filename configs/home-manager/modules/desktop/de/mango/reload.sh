#!/usr/bin/env bash
set -euo pipefail

pkill waybar

mmsg -d reload_config

waybar -c ~/.config/waybar/mango.jsonc -s ~/.config/waybar/mango.css &

systemctl --user restart qs-quick-actions.service 2>/dev/null || {
  systemctl --user start qs-quick-actions.service 2>/dev/null || true
}

systemctl --user restart swaync.service 2>/dev/null || {
  pkill swaync 2>/dev/null || true
  swaync >/dev/null 2>&1 &
}
