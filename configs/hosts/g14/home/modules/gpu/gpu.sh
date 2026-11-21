notify() {
  notify-send "$1" "$2" --app-name=amane-gpu 2>/dev/null || true
}

normalize() {
  printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]//g'
}

if ! current="$(supergfxctl --get 2>&1)"; then
  notify "GPU switch failed" "$current"
  exit 1
fi

if ! supported="$(supergfxctl --supported 2>&1)"; then
  notify "GPU switch failed" "$supported"
  exit 1
fi

current_norm="$(normalize "$current")"
supported_norm="$(normalize "$supported")"
options=""

add_option() {
  mode="$1"
  label="$2"
  mode_norm="$(normalize "$mode")"

  if ! printf '%s' "$supported_norm" | grep -q "$mode_norm"; then
    return
  fi

  prefix="  "
  if [ "$current_norm" = "$mode_norm" ]; then
    prefix="* "
  fi

  options="$options$prefix$label"$'\n'
}

add_option "Integrated" "Integrated"
add_option "Hybrid" "Hybrid"
add_option "AsusMuxDgpu" "AMDMuxDgpu"

if [ -z "$options" ]; then
  notify "GPU switch failed" "No supported GPU modes reported"
  exit 1
fi

choice="$(printf '%s' "$options" | amane-dmenu -dmenu -i -p "GPU: $current")"
menu_exit=$?

if [ "$menu_exit" -ne 0 ] || [ -z "$choice" ]; then
  exit 0
fi

case "$choice" in
  *Integrated*)
    target_mode="Integrated"
    target_label="Integrated"
    ;;
  *Hybrid*)
    target_mode="Hybrid"
    target_label="Hybrid"
    ;;
  *AMDMuxDgpu*|*AsusMuxDgpu*)
    target_mode="AsusMuxDgpu"
    target_label="AMDMuxDgpu"
    ;;
  *)
    notify "GPU switch failed" "Unknown selection: $choice"
    exit 1
    ;;
esac

if ! switch_output="$(supergfxctl --mode "$target_mode" 2>&1)"; then
  notify "GPU switch failed" "$switch_output"
  exit 1
fi

pending_action="$(supergfxctl --pend-action 2>/dev/null || true)"
pending_mode="$(supergfxctl --pend-mode 2>/dev/null || true)"
body="Requested: $target_label"

if [ -n "$pending_mode" ] && [ "$(normalize "$pending_mode")" != "unknown" ]; then
  body="$body"$'\n'"Pending mode: $pending_mode"
fi

case "$(normalize "$pending_action")" in
  ""|unknown|noactionrequired|nothing)
    body="$body"$'\n'"No action required."
    ;;
  *logout*)
    body="$body"$'\n'"Log out and back in to fully apply the change."
    ;;
  *reboot*)
    body="$body"$'\n'"Reboot to fully apply the change."
    ;;
  *)
    body="$body"$'\n'"$pending_action"
    ;;
esac

notify "GPU mode switched" "$body"
