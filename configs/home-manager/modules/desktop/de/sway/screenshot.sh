#!/usr/bin/env bash
set -euo pipefail

FILENAME="Screenshot-$(date +%F_%T).png"
TARGET_DIR="$HOME/Pictures/Screenshots"
SAVE_PATH="$TARGET_DIR/$FILENAME"

mkdir -p "$TARGET_DIR"

notify() {
  if command -v notify-send >/dev/null 2>&1; then
    notify-send "Screenshot" "$1"
  elif command -v dunstify >/dev/null 2>&1; then
    dunstify "Screenshot" "$1"
  fi
}

# Avoid multiple concurrent screenshot/selection tools
if pgrep -x slurp >/dev/null 2>&1 \
  || pgrep -x grimblast >/dev/null 2>&1 \
  || pgrep -x grimshot >/dev/null 2>&1; then
  exit 1
fi

# ---- Hyprland-specific path ----
if command -v grimblast >/dev/null 2>&1 && [ -n "${HYPRLAND_INSTANCE_SIGNATURE-}" ]; then
  if grimblast --freeze copysave area "$SAVE_PATH"; then
    notify "Saved: $SAVE_PATH (and copied)"
    exit 0
  else
    notify "Screenshot cancelled"
    exit 1
  fi
fi

# ---- Sway-specific path ----
# "anything" = click a window, click an output, or drag an area
if command -v grimshot >/dev/null 2>&1 && [ -n "${SWAYSOCK-}" ]; then
  if grimshot savecopy anything "$SAVE_PATH" >/dev/null 2>&1; then
    notify "Saved: $SAVE_PATH (and copied)"
    exit 0
  else
    notify "Screenshot cancelled"
    exit 1
  fi
fi

# ---- Generic Wayland fallback ----
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

TMP_FILE="$(mktemp --suffix=.png)"
grim -g "$REGION" "$TMP_FILE"
wl-copy <"$TMP_FILE"
mv "$TMP_FILE" "$SAVE_PATH"

[[ -n "${FREEZE_PID:-}" ]] && kill -TERM "$FREEZE_PID" 2>/dev/null || true
notify "Saved: $SAVE_PATH (and copied)"
