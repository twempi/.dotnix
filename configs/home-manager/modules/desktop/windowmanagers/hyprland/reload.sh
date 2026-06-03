#!/usr/bin/env bash

set -u

waybar_config="${XDG_CONFIG_HOME:-$HOME/.config}/waybar/hyprland.jsonc"
waybar_style="${XDG_CONFIG_HOME:-$HOME/.config}/waybar/hyprland.css"

pkill -x rofi 2>/dev/null || true

hyprctl reload

systemctl --user restart swaync.service || true

pkill waybar

if command -v uwsm >/dev/null 2>&1 && uwsm check is-active >/dev/null 2>&1; then
  uwsm app -- waybar -c "$waybar_config" -s "$waybar_style"
else
  waybar -c "$waybar_config" -s "$waybar_style" >/dev/null 2>&1 &
fi
