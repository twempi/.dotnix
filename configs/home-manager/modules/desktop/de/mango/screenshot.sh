#!/usr/bin/env bash
set -euo pipefail

FILENAME="Screenshot-$(date +%F_%H-%M-%S).png"
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

need() {
  if ! command -v "$1" >/dev/null 2>&1; then
    notify "Missing dependency: $1"
    exit 1
  fi
}

# Avoid multiple concurrent region selectors
if pgrep -x slurp >/dev/null 2>&1; then
  notify "Screenshot already in progress"
  exit 1
fi

# Give MangoWC time to release the screenshot keybind before slurp grabs input
sleep 0.15

# Only use grimblast inside Hyprland, not MangoWC
if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && command -v grimblast >/dev/null 2>&1; then
  if grimblast --freeze copysave area "$SAVE_PATH"; then
    notify "Saved: $SAVE_PATH and copied"
    exit 0
  else
    notify "Screenshot cancelled"
    exit 1
  fi
fi

# MangoWC / generic wlroots Wayland path
need grim
need slurp
need wl-copy

TMP="$(mktemp --tmpdir screenshot.XXXXXX.png)"
trap 'rm -f "$TMP"' EXIT

REGION="$(slurp || true)"

if [[ -z "$REGION" ]]; then
  notify "Screenshot cancelled"
  exit 1
fi

if grim -l 0 -g "$REGION" "$TMP"; then
  wl-copy <"$TMP"
  mv "$TMP" "$SAVE_PATH"
  trap - EXIT
  notify "Saved: $SAVE_PATH and copied"
else
  notify "Screenshot failed"
  exit 1
fi
