#!/usr/bin/env bash
set -euo pipefail

FILENAME="Screenshot-$(date +%F_%T).png"
TARGET_DIR="$HOME/Pictures/Screenshots"
SAVE_PATH="$TARGET_DIR/$FILENAME"

mkdir -p "$TARGET_DIR"

# lightweight notifier (uses notify-send if present, else dunstify)
notify() {
  if command -v notify-send >/dev/null 2>&1; then
    notify-send "Screenshot" "$1"
  elif command -v dunstify >/dev/null 2>&1; then
    dunstify "Screenshot" "$1"
  fi
}

# Avoid multiple concurrent selection tools
if pgrep -x slurp >/dev/null 2>&1 || pgrep -x grimblast >/dev/null 2>&1; then
  exit 1
fi

if command -v grimblast >/dev/null 2>&1; then
  # Hyprland-native freeze + select + copy + save
  if grimblast --freeze copysave area "$SAVE_PATH"; then
    notify "Saved: $SAVE_PATH (and copied)"
    exit 0
  else
    notify "Screenshot cancelled"
    exit 1
  fi
fi

# ---- Fallback path (generic Wayland): freeze overlay + slurp + grim ----
FREEZE_PID=""
if command -v wayfreeze >/dev/null 2>&1; then
  wayfreeze &
  FREEZE_PID=$!
  trap '[[ -n "${FREEZE_PID:-}" ]] && kill -TERM "$FREEZE_PID" 2>/dev/null || true' EXIT
  sleep 0.12
fi

REGION="$(slurp || true)"
if [ -z "$REGION" ]; then
  notify "Screenshot cancelled"
  exit 1
fi

grim -g "$REGION" /tmp/screenshot_temp.png
wl-copy </tmp/screenshot_temp.png
mv /tmp/screenshot_temp.png "$SAVE_PATH"
rm -f /tmp/screenshot_temp.png

[[ -n "${FREEZE_PID:-}" ]] && kill -TERM "$FREEZE_PID" 2>/dev/null || true
notify "Saved: $SAVE_PATH (and copied)"
