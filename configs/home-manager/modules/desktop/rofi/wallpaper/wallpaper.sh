#!/usr/bin/env bash

set -u

wallpapers_dir="$HOME/Pictures/wallpapers"
theme="$HOME/.config/rofi/themes/wallpaper.rasi"

notify() {
  notify-send "Wallpaper" "$1" --app-name=rofi-wallpaper 2>/dev/null || true
}

if [ ! -d "$wallpapers_dir" ]; then
  notify "Directory not found: $wallpapers_dir"
  exit 0
fi

rofi_cmd=(
  rofi -dmenu -i -show-icons \
    -p "Wallpaper" \
    -theme "$theme"
)

choice=$(
  find "$wallpapers_dir" -maxdepth 1 -type f \
    \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) \
    -printf '%f\0' |
    sort -zV |
    while IFS= read -r -d '' filename; do
      printf "%s\x00icon\x1f%s/%s\n" "$filename" "$wallpapers_dir" "$filename"
    done |
    "${rofi_cmd[@]}"
)
rofi_exit=$?

if [ "$rofi_exit" -ne 0 ] || [ -z "$choice" ]; then
  exit 0
fi

WALLPAPER="$wallpapers_dir/$choice"

if [ ! -f "$WALLPAPER" ]; then
  notify "Wallpaper not found: $choice"
  exit 1
fi

lower_choice="$(printf '%s' "$choice" | tr '[:upper:]' '[:lower:]')"
case "$lower_choice" in
  *.jpg|*.jpeg|*.png|*.webp) ;;
  *)
    notify "Unsupported wallpaper type: $choice"
    exit 1
    ;;
esac

if awww img "$WALLPAPER" \
  --transition-type any \
  --transition-duration 2 \
  --transition-step 255 \
  --transition-fps 60; then
  notify-send "Wallpaper Changed" -i "$WALLPAPER" --app-name=awww
else
  notify-send "Wallpaper Failed" "$choice" --app-name=awww 2>/dev/null || true
  exit 1
fi

# matugen image "$WALLPAPER"

exit 0
