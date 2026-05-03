#!/usr/bin/env bash

# Current Theme
dir="$HOME/.config/rofi/themes"
theme='powermenu'

# CMDs
uptime="$(uptime -p | sed -e 's/up //g')"
host="$(hostname)"

# Options
shutdown='⏻ Shutdown'
reboot=' Reboot'
lock=' Lock'
suspend=' Suspend'
logout='󰍃 Logout'

# Rofi CMD
rofi_cmd() {
  rofi -dmenu \
    -p "$host" \
    -mesg "Uptime: $uptime" \
    -theme "${dir}/${theme}.rasi" \
    -kb-custom-1 'p' \
    -kb-custom-2 'r' \
    -kb-custom-3 's' \
    -kb-custom-4 'l'
  # p = poweroff, r = reboot, s = suspend, l = logout
}

# Pass variables to rofi dmenu
run_rofi() {
  printf '%s\n%s\n%s\n%s\n%s\n' \
    "$lock" "$suspend" "$logout" "$reboot" "$shutdown" | rofi_cmd
  return $?
}

# Execute Command (no confirmation)
run_cmd() {
  case "$1" in
    --shutdown)
      systemctl poweroff
      ;;
    --reboot)
      systemctl reboot
      ;;
    --suspend)
      mpc -q pause 2>/dev/null || true
      amixer set Master mute 2>/dev/null || true
      systemctl suspend
      ;;
    --logout)
      # Wayland compositors
      if [[ -n "$SWAYSOCK" ]] && command -v swaymsg >/dev/null; then
        swaymsg exit
      elif [[ -n "$HYPRLAND_INSTANCE_SIGNATURE" ]] && command -v hyprctl >/dev/null; then
        hyprctl dispatch exit
      elif command -v niri >/dev/null && niri msg --help >/dev/null 2>&1; then
        niri msg exit

      # Fallbacks (X11 / legacy)
      elif [[ "$DESKTOP_SESSION" == 'openbox' ]]; then
        openbox --exit
      elif [[ "$DESKTOP_SESSION" == 'bspwm' ]]; then
        bspc quit
      elif [[ "$DESKTOP_SESSION" == 'i3' ]]; then
        i3-msg exit
      elif [[ "$DESKTOP_SESSION" == 'plasma' ]]; then
        qdbus org.kde.ksmserver /KSMServer logout 0 0 0
      else
        notify-send "Logout failed" "No supported compositor/session detected"
      fi
      ;;
  esac
}

# Actions
chosen="$(run_rofi)"
rofi_exit=$?

# Handle custom keybindings
case "$rofi_exit" in
10) run_cmd --shutdown ;;
11) run_cmd --reboot ;;
12) run_cmd --suspend ;;
13) run_cmd --logout ;;
esac

# Normal selection (Enter / mouse)
case "$chosen" in
"$shutdown") run_cmd --shutdown ;;
"$reboot")   run_cmd --reboot ;;
"$lock")
  if command -v hyprlock >/dev/null; then
    hyprlock
  else
    notify-send "Lock failed" "hyprlock not found"
  fi
  ;;
"$suspend")  run_cmd --suspend ;;
"$logout")   run_cmd --logout ;;
esac
