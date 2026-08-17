{
  inputs,
  pkgs,
  system,
}:
pkgs.writeShellApplication {
  name = "g14-refresh-rate";

  runtimeInputs = [
    pkgs.upower
    pkgs.jq
    pkgs.gnugrep
    pkgs.gawk
    pkgs.coreutils
    pkgs.sway
    inputs.hyprland.packages.${system}.hyprland
    pkgs.wlr-randr
    pkgs.dbus
    pkgs.systemd
  ];

  text = ''
    output_pattern='^eDP-[0-9]+$'
    resolution="2560x1600"

    usage() {
      printf 'Usage: %s [--once|--watch|--session-start]\n' "$0" >&2
    }

    ac_online_upower() {
      local device details online
      local saw_offline="false"

      while IFS= read -r device; do
        details="$(upower -i "$device" 2>/dev/null || true)"
        if ! printf '%s\n' "$details" | grep -q '^[[:space:]]*type:[[:space:]]*line-power'; then
          continue
        fi

        online="$(
          printf '%s\n' "$details" \
            | awk -F: '/^[[:space:]]*online:/ {gsub(/^[[:space:]]+|[[:space:]]+$/, "", $2); print $2; exit}'
        )"

        case "$online" in
          yes|true|1)
            return 0
            ;;
          no|false|0)
            saw_offline="true"
            ;;
        esac
      done < <(upower -e 2>/dev/null || true)

      if [ "$saw_offline" = "true" ]; then
        return 1
      fi

      return 2
    }

    ac_online_sysfs() {
      local supply supply_type online
      local saw_offline="false"

      for supply in /sys/class/power_supply/*; do
        [ -d "$supply" ] || continue
        [ -r "$supply/type" ] || continue
        [ -r "$supply/online" ] || continue

        supply_type="$(cat "$supply/type" 2>/dev/null || true)"
        case "$supply_type" in
          Mains|USB*|Wireless)
            ;;
          *)
            continue
            ;;
        esac

        online="$(cat "$supply/online" 2>/dev/null || true)"
        case "$online" in
          1)
            return 0
            ;;
          0)
            saw_offline="true"
            ;;
        esac
      done

      if [ "$saw_offline" = "true" ]; then
        return 1
      fi

      return 2
    }

    target_hz() {
      local status

      if ac_online_upower; then
        printf '120\n'
        return 0
      else
        status="$?"
      fi

      if [ "$status" -eq 1 ]; then
        printf '60\n'
        return 0
      fi

      if ac_online_sysfs; then
        printf '120\n'
        return 0
      else
        status="$?"
      fi

      if [ "$status" -eq 2 ]; then
        printf 'Could not determine AC state; defaulting to 60Hz\n' >&2
      fi
      printf '60\n'
    }

    active_compositor() {
      local desktop="''${XDG_CURRENT_DESKTOP:-}"
      desktop="''${desktop,,}"

      case "$desktop" in
        *hyprland*)
          printf 'hyprland\n'
          return 0
          ;;
        *sway*)
          printf 'sway\n'
          return 0
          ;;
        *mango*)
          printf 'mango\n'
          return 0
          ;;
      esac

      if [ -n "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ]; then
        printf 'hyprland\n'
      elif [ -n "''${SWAYSOCK:-}" ]; then
        printf 'sway\n'
      elif [ -n "''${MANGO_INSTANCE_SIGNATURE:-}" ]; then
        printf 'mango\n'
      else
        printf 'Could not identify the active compositor\n' >&2
        return 1
      fi
    }

    internal_output_hyprland() {
      local outputs

      outputs="$(hyprctl monitors -j 2>/dev/null)" || return 1
      printf '%s\n' "$outputs" \
        | jq -r --arg pattern "$output_pattern" 'first(.[] | select(.name | test($pattern)) | .name) // empty'
    }

    internal_output_sway() {
      local outputs

      outputs="$(swaymsg -t get_outputs -r 2>/dev/null)" || return 1
      printf '%s\n' "$outputs" \
        | jq -r --arg pattern "$output_pattern" 'first(.[] | select(.active == true and (.name | test($pattern))) | .name) // empty'
    }

    internal_output_mango() {
      local outputs

      outputs="$(wlr-randr --json 2>/dev/null)" || return 1
      printf '%s\n' "$outputs" \
        | jq -r --arg pattern "$output_pattern" 'first(.[] | select(.enabled == true and (.name | test($pattern))) | .name) // empty'
    }

    internal_output() {
      local compositor="$1"

      case "$compositor" in
        hyprland)
          internal_output_hyprland
          ;;
        sway)
          internal_output_sway
          ;;
        mango)
          internal_output_mango
          ;;
        *)
          return 1
          ;;
      esac
    }

    apply_hyprland() {
      local output="$1"
      local hz="$2"
      local response

      response="$(hyprctl eval "hl.monitor({ output = '$output', mode = '$resolution@$hz' })" 2>&1)" || {
        printf '%s\n' "$response" >&2
        return 1
      }

      if [ "$response" != "ok" ]; then
        printf 'Hyprland rejected the refresh-rate change: %s\n' "$response" >&2
        return 1
      fi
    }

    apply_sway() {
      local output="$1"
      local hz="$2"
      local response

      response="$(swaymsg output "$output" mode "$resolution@$hz.000Hz" 2>&1)" || {
        printf '%s\n' "$response" >&2
        return 1
      }

      if ! printf '%s\n' "$response" | jq -e 'type == "array" and length > 0 and all(.[]; .success == true)' >/dev/null; then
        printf 'Sway rejected the refresh-rate change: %s\n' "$response" >&2
        return 1
      fi
    }

    apply_mango() {
      local output="$1"
      local hz="$2"

      wlr-randr --output "$output" --mode "$resolution@$hz"
    }

    apply_refresh_rate() {
      local compositor="$1"
      local output="$2"
      local hz="$3"

      case "$compositor" in
        hyprland)
          apply_hyprland "$output" "$hz"
          ;;
        sway)
          apply_sway "$output" "$hz"
          ;;
        mango)
          apply_mango "$output" "$hz"
          ;;
        *)
          return 1
          ;;
      esac
    }

    sync_refresh_rate() {
      local compositor output hz

      compositor="$(active_compositor)" || return 1
      if ! output="$(internal_output "$compositor")"; then
        printf 'Could not query outputs from %s\n' "$compositor" >&2
        return 1
      fi

      # The internal panel may be intentionally disabled by clamshell mode.
      [ -n "$output" ] || return 0

      hz="$(target_hz)"
      if ! apply_refresh_rate "$compositor" "$output" "$hz"; then
        printf 'Could not apply %sHz to %s on %s\n' "$hz" "$output" "$compositor" >&2
        return 1
      fi
    }

    watch_refresh_rate() {
      local event

      sync_refresh_rate

      while IFS= read -r event; do
        case "$event" in
          */line_power_*)
            sync_refresh_rate
            ;;
        esac
      done < <(upower --monitor)

      printf 'UPower monitor stopped unexpectedly\n' >&2
      return 1
    }

    session_start() {
      if [ -z "''${WAYLAND_DISPLAY:-}" ]; then
        printf 'WAYLAND_DISPLAY is not available in this compositor session\n' >&2
        return 1
      fi

      dbus-update-activation-environment --systemd \
        WAYLAND_DISPLAY \
        HYPRLAND_INSTANCE_SIGNATURE \
        SWAYSOCK \
        MANGO_INSTANCE_SIGNATURE \
        XDG_CURRENT_DESKTOP \
        XDG_SESSION_TYPE

      systemctl --user reset-failed g14-refresh-rate.service || true
      systemctl --user start g14-refresh-rate.service
    }

    case "''${1:---once}" in
      --once)
        sync_refresh_rate
        ;;
      --watch)
        watch_refresh_rate
        ;;
      --session-start)
        session_start
        ;;
      -h|--help)
        usage
        ;;
      *)
        usage
        exit 64
        ;;
    esac
  '';
}
