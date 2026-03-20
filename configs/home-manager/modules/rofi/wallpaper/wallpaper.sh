#!/usr/bin/env bash

wallpapers_dir="$HOME/Pictures/wallpapers/"
theme="$HOME/.config/rofi/themes/wallpaper.rasi"

rofi_cmd=(
  rofi -dmenu -i -show-icons \
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

[[ -z "$choice" ]] && exit 0

WALLPAPER="$wallpapers_dir/$choice"

swww img "$WALLPAPER" \
  --transition-type any \
  --transition-duration 2 \
  --transition-step 255 \
  --transition-fps 60 &&
  notify-send "Wallpaper Changed" -i "$WALLPAPER" --app-name=swww

# matugen image "$WALLPAPER"

exit 0
