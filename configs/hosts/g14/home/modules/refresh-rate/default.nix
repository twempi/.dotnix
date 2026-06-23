{
  inputs,
  pkgs,
  system,
  ...
}: let
  hyprlandPackage = inputs.hyprland.packages.${system}.hyprland;

  g14RefreshRate = pkgs.writeShellApplication {
    name = "g14-refresh-rate";

    runtimeInputs = [
      pkgs.upower
      pkgs.jq
      pkgs.gnugrep
      pkgs.gawk
      pkgs.coreutils
      pkgs.sway
      hyprlandPackage
      pkgs.wlr-randr
    ];

    text = ''
      output_pattern='^eDP-[0-9]+$'
      resolution="2560x1600"
      scale="1.5"
      position_hyprland="0x0"
      position_wlroots="0,0"
      current_hz=""

      usage() {
        printf 'Usage: %s [--once|--watch]\n' "$0" >&2
      }

      ac_online_upower() {
        local device details online

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
              return 1
              ;;
          esac
        done < <(upower -e 2>/dev/null || true)

        return 2
      }

      ac_online_sysfs() {
        local supply online

        for supply in /sys/class/power_supply/*/online; do
          [ -e "$supply" ] || continue

          online="$(cat "$supply" 2>/dev/null || true)"
          case "$online" in
            1)
              return 0
              ;;
            0)
              return 1
              ;;
          esac
        done

        return 2
      }

      target_hz() {
        if ac_online_upower; then
          printf '120\n'
          return 0
        fi

        case "$?" in
          1)
            printf '60\n'
            return 0
            ;;
        esac

        if ac_online_sysfs; then
          printf '120\n'
        else
          printf '60\n'
        fi
      }

      internal_output_from_hyprland() {
        local candidate

        [ -n "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ] || return 1
        candidate="$(
          hyprctl monitors -j 2>/dev/null \
            | jq -r --arg pattern "$output_pattern" '.[] | select(.name | test($pattern)) | .name' \
            | head -n1 \
            || true
        )"

        [ -n "$candidate" ] || return 1
        printf '%s\n' "$candidate"
      }

      internal_output_from_sway() {
        local candidate

        [ -n "''${SWAYSOCK:-}" ] || return 1
        candidate="$(
          swaymsg -t get_outputs -r 2>/dev/null \
            | jq -r --arg pattern "$output_pattern" '.[] | select(.active == true and (.name | test($pattern))) | .name' \
            | head -n1 \
            || true
        )"

        [ -n "$candidate" ] || return 1
        printf '%s\n' "$candidate"
      }

      internal_output_from_wlroots() {
        local candidate

        candidate="$(
          wlr-randr 2>/dev/null \
            | awk '/^[^[:space:]]/ && $1 ~ /^eDP-[0-9]+$/ {print $1; exit}' \
            || true
        )"

        [ -n "$candidate" ] || return 1
        printf '%s\n' "$candidate"
      }

      internal_output() {
        internal_output_from_hyprland \
          || internal_output_from_sway \
          || internal_output_from_wlroots
      }

      apply_hyprland() {
        local output="$1"
        local hz="$2"

        [ -n "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ] || return 1
        hyprctl keyword monitor "$output,$resolution@$hz,$position_hyprland,$scale"
      }

      apply_sway() {
        local output="$1"
        local hz="$2"

        [ -n "''${SWAYSOCK:-}" ] || return 1
        swaymsg output "$output" mode "$resolution@$hz.000Hz" pos 0 0 scale "$scale"
      }

      apply_wlroots() {
        local output="$1"
        local hz="$2"

        wlr-randr | grep -q "^$output" || return 1
        wlr-randr --output "$output" --mode "$resolution@$hz" --pos "$position_wlroots" --scale "$scale"
      }

      apply_refresh_rate() {
        local hz="$1"
        local output

        output="$(internal_output || true)"
        [ -n "$output" ] || return 1

        if apply_hyprland "$output" "$hz"; then
          return 0
        fi

        if apply_sway "$output" "$hz"; then
          return 0
        fi

        apply_wlroots "$output" "$hz"
      }

      sync_refresh_rate() {
        local hz

        hz="$(target_hz)"
        if [ "$hz" = "$current_hz" ]; then
          return 0
        fi

        if apply_refresh_rate "$hz"; then
          current_hz="$hz"
        else
          printf 'Could not apply %sHz to an internal eDP panel in this Wayland session\n' "$hz" >&2
        fi
      }

      watch_refresh_rate() {
        sync_refresh_rate

        upower --monitor-detail 2>/dev/null | while IFS= read -r _event; do
          sync_refresh_rate
        done
      }

      case "''${1:---once}" in
        --once)
          sync_refresh_rate
          ;;
        --watch)
          watch_refresh_rate
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
  };
in {
  home.packages = [
    g14RefreshRate
  ];

  systemd.user.services.g14-refresh-rate = {
    Unit = {
      Description = "Set G14 internal panel refresh rate from AC state";
      PartOf = ["graphical-session.target"];
      After = ["graphical-session.target"];
      ConditionEnvironment = ["WAYLAND_DISPLAY"];
    };

    Service = {
      Type = "simple";
      ExecStart = "${g14RefreshRate}/bin/g14-refresh-rate --watch";
      Restart = "on-failure";
      RestartSec = "5s";
      Slice = "background.slice";
    };

    Install = {
      WantedBy = ["graphical-session.target"];
    };
  };
}
