#!/usr/bin/env bash
set -euo pipefail

pkill rofi 2>/dev/null || true

mmsg -d reload_config

# qs-top-bar restart 2>/dev/null || true
systemctl --user restart qs-quick-actions.service 2>/dev/null || {
  systemctl --user start qs-quick-actions.service 2>/dev/null || true
}

systemctl --user restart swaync.service 2>/dev/null || {
  pkill swaync 2>/dev/null || true
  swaync >/dev/null 2>&1 &
}
