cards=()
ordered=()

add_card() {
  local candidate="$1"
  local existing

  for existing in "${ordered[@]}"; do
    if [[ "$existing" == "$candidate" ]]; then
      return
    fi
  done

  ordered+=("$candidate")
}

has_connector_prefix() {
  local card="$1"
  local prefix="$2"
  local connector_path
  local connector_name

  for connector_path in /sys/class/drm/"$card"-*; do
    [[ -e "$connector_path" ]] || continue
    [[ -d "$connector_path" ]] || continue

    connector_name="${connector_path##*/}"
    connector_name="${connector_name#"$card"-}"

    if [[ "$connector_name" == "$prefix"* ]]; then
      return 0
    fi
  done

  return 1
}

for sys_card in /sys/class/drm/card[0-9]; do
  [[ -e "$sys_card" ]] || continue

  card="${sys_card##*/}"
  [[ -e "/dev/dri/$card" ]] || continue

  cards+=("$card")
done

for card in "${cards[@]}"; do
  if has_connector_prefix "$card" "eDP-"; then
    add_card "$card"
  fi
done

for card in "${cards[@]}"; do
  if has_connector_prefix "$card" "HDMI-A-"; then
    add_card "$card"
  fi
done

for card in "${cards[@]}"; do
  add_card "$card"
done

output=""
for card in "${ordered[@]}"; do
  if [[ -n "$output" ]]; then
    output+=":"
  fi

  output+="/dev/dri/$card"
done

printf '%s\n' "$output"
