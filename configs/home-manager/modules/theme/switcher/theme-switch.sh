# state_dir and sway_reload are set by default.nix.
base="$state_dir/base"
current_file="$state_dir/current"

usage() {
  echo "Usage: theme-switch [--pick | --list | --current | --restore | <scheme>]"
}

require_base() {
  if [[ ! -d "$base/specialisation" ]]; then
    echo "theme-switch: no base generation recorded yet; run hms once" >&2
    exit 1
  fi
}

list_schemes() {
  local dir
  for dir in "$base"/specialisation/*; do
    echo "${dir##*/}"
  done
}

# Every prebuilt scheme carries its own palette file for Amane's swatches.
theme_rows() {
  local dir
  for dir in "$base"/specialisation/*; do
    printf '%s\0colors\x1f%s\n' "${dir##*/}" "$dir/home-files/.config/amane-shell/colors"
  done
}

reload_apps() {
  # kitty re-reads kitty.conf on SIGUSR1.
  pkill -USR1 -x kitty || true

  if tmux info >/dev/null 2>&1; then
    tmux source-file "$HOME/.config/tmux/tmux.conf" || true
  fi

  if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    hyprctl reload >/dev/null || true
  elif [[ -n "${SWAYSOCK:-}" ]]; then
    "$sway_reload" >/dev/null || true
  elif command -v mmsg >/dev/null; then
    mmsg dispatch reload_config >/dev/null 2>&1 || true
  fi

  # Helium only picks up its UI colour when its launcher starts it fresh.
  if pgrep -f '/opt/helium/helium( |$)' >/dev/null; then
    echo "theme-switch: restart Helium to apply its UI colour" >&2
  fi
}

switch_to() {
  local scheme="$1"
  require_base

  exec 9>"$state_dir/lock"
  if ! flock -n 9; then
    echo "theme-switch: another theme switch is still running" >&2
    exit 1
  fi

  if [[ ! -x "$base/specialisation/$scheme/activate" ]]; then
    echo "theme-switch: unknown scheme '$scheme'" >&2
    echo "Available schemes:" >&2
    list_schemes >&2
    exit 1
  fi

  "$base/specialisation/$scheme/activate" 9>&-
  echo "$scheme" >"$current_file"
  reload_apps
}

pick() {
  require_base
  local current choice
  current=$(cat "$current_file" 2>/dev/null || echo "default")

  # Escape in the launcher exits non-zero or prints nothing. Amane runs on Sway and Hyprland.
  choice=$(theme_rows | amane-dmenu -dmenu -i -p "Theme ($current)" -theme themes) || exit 0
  [[ -n "$choice" ]] || exit 0

  # Run as a separate process so errexit still applies inside the switch.
  if "$0" "$choice"; then
    notify-send --app-name=theme-switch "Theme switched" "$choice" || true
  else
    notify-send --app-name=theme-switch --urgency=critical "Theme switch failed" "$choice" || true
    exit 1
  fi
}

case "${1:-}" in
  "" | -h | --help)
    usage
    ;;
  --pick)
    pick
    ;;
  --list)
    require_base
    list_schemes
    ;;
  --current)
    cat "$current_file" 2>/dev/null || echo "(default)"
    ;;
  --restore)
    # A normal hms activates the default scheme; re-apply the last pick.
    if [[ -s "$current_file" ]]; then
      switch_to "$(cat "$current_file")"
    fi
    ;;
  *)
    switch_to "$1"
    ;;
esac
