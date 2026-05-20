{
  inputs,
  pkgs,
  system,
  ...
}: let
  mangoPackage = import ../de/mango/mango-patched.nix {
    inherit inputs pkgs system;
  };

  wayScreenshot = pkgs.writeShellApplication {
    name = "way-screenshot";
    runtimeInputs = with pkgs;
      [
        bash
        coreutils
        gawk
        grim
        hyprland
        hyprpicker
        jq
        libnotify
        slurp
        sway
        wayfreeze
        wl-clipboard
      ]
      ++ [
        mangoPackage
      ];
    text = ''
      set -euo pipefail

      usage() {
        cat >&2 <<'EOF'
      usage: way-screenshot <area|screen>

      area    interactively select a window rectangle or arbitrary region
      screen  capture all visible outputs
      EOF
      }

      notify_screenshot() {
        if [ "''${WAY_SCREENSHOT_NOTIFY:-1}" = "0" ]; then
          return 0
        fi

        notify-send -a way-screenshot "Screenshot" "$1" >/dev/null 2>&1 || true
      }

      fail() {
        notify_screenshot "$1"
        printf 'way-screenshot: %s\n' "$1" >&2
        exit 1
      }

      need() {
        if ! command -v "$1" >/dev/null 2>&1; then
          fail "Missing dependency: $1"
        fi
      }

      mode="''${1:-area}"
      case "$mode" in
        area | screen) ;;
        -h | --help | help)
          usage
          exit 0
          ;;
        *)
          usage
          exit 64
          ;;
      esac

      need grim
      need wl-copy

      target_dir="''${WAY_SCREENSHOT_DIR:-$HOME/Pictures/Screenshots}"
      mkdir -p "$target_dir"

      filename="Screenshot-$(date +%Y-%m-%d_%H-%M-%S).png"
      save_path="$target_dir/$filename"
      runtime_dir="''${XDG_RUNTIME_DIR:-/tmp}"
      lock_dir="$runtime_dir/way-screenshot.lock"
      tmp_file=""
      freeze_pid=""

      cleanup() {
        if [ -n "$freeze_pid" ]; then
          kill "$freeze_pid" >/dev/null 2>&1 || true
        fi
        if [ -n "$tmp_file" ]; then
          rm -f "$tmp_file"
        fi
        rmdir "$lock_dir" >/dev/null 2>&1 || true
      }

      if ! mkdir "$lock_dir" >/dev/null 2>&1; then
        fail "Screenshot already in progress"
      fi
      trap cleanup EXIT INT TERM

      start_freeze() {
        if [ "''${WAY_SCREENSHOT_FREEZE:-0}" != "1" ]; then
          return 0
        fi

        if [ -n "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ] && command -v hyprpicker >/dev/null 2>&1; then
          hyprpicker -rz >/dev/null 2>&1 &
          freeze_pid="$!"
          sleep 0.2
          return 0
        fi

        if command -v wayfreeze >/dev/null 2>&1; then
          wayfreeze >/dev/null 2>&1 &
          freeze_pid="$!"
          sleep 0.12
        fi
      }

      capture_region() {
        local region="$1"

        tmp_file="$(mktemp --tmpdir way-screenshot.XXXXXX.png)"
        if ! grim -g "$region" "$tmp_file"; then
          fail "Screenshot failed"
        fi

        if ! wl-copy --type image/png <"$tmp_file"; then
          fail "Clipboard copy failed"
        fi

        mv "$tmp_file" "$save_path"
        tmp_file=""
        notify_screenshot "Saved: $save_path (and copied)"
        printf '%s\n' "$save_path"
      }

      capture_screen() {
        tmp_file="$(mktemp --tmpdir way-screenshot.XXXXXX.png)"
        if ! grim "$tmp_file"; then
          fail "Screenshot failed"
        fi

        if ! wl-copy --type image/png <"$tmp_file"; then
          fail "Clipboard copy failed"
        fi

        mv "$tmp_file" "$save_path"
        tmp_file=""
        notify_screenshot "Saved: $save_path (and copied)"
        printf '%s\n' "$save_path"
      }

      hyprland_rects() {
        [ -n "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ] || return 1
        command -v hyprctl >/dev/null 2>&1 || return 1
        command -v jq >/dev/null 2>&1 || return 1

        local workspaces fullscreen_workspaces
        workspaces="$(hyprctl monitors -j 2>/dev/null | jq -c '[(foreach .[] as $monitor (0; if $monitor.specialWorkspace.name == "" then $monitor.activeWorkspace else $monitor.specialWorkspace end)).id]')" || return 1
        fullscreen_workspaces="$(hyprctl workspaces -j 2>/dev/null | jq -c 'map(select(.hasfullscreen) | .id)')" || return 1

        hyprctl clients -j 2>/dev/null | jq -r \
          --argjson workspaces "$workspaces" \
          --argjson fullscreenWorkspaces "$fullscreen_workspaces" '
            map(select(
              (([.workspace.id] | inside($workspaces))
                and (([.workspace.id] | inside($fullscreenWorkspaces) | not) or .fullscreen > 0))
            ))
            | .[]
            | select(.mapped == true and .hidden == false and .size[0] > 0 and .size[1] > 0)
            | "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1]) \(.class // "window")"
          '
      }

      sway_rects() {
        [ -n "''${SWAYSOCK:-}" ] || return 1
        command -v swaymsg >/dev/null 2>&1 || return 1
        command -v jq >/dev/null 2>&1 || return 1

        swaymsg -t get_tree --raw 2>/dev/null | jq -r '
          def leaves:
            if (((.nodes // []) | length) == 0 and ((.floating_nodes // []) | length) == 0) then
              .
            else
              ((.nodes // [])[] | leaves),
              ((.floating_nodes // [])[] | leaves)
            end;

          .nodes[]?
          | .nodes[]?
          | select(.type == "workspace" and .visible == true)
          | leaves
          | select(.type == "con" and (.pid? != null) and (.rect.width > 0) and (.rect.height > 0))
          | "\(.rect.x),\(.rect.y) \(.rect.width)x\(.rect.height) \(.app_id // .window_properties.class // .name // "window")"
        '
      }

      mango_rects() {
        command -v mmsg >/dev/null 2>&1 || return 1

        local output
        output="$(mmsg -g -o 2>/dev/null | awk '$2 == "selmon" && $3 == "1" { print $1; exit }')" || return 1
        [ -n "$output" ] || return 1

        mmsg -o "$output" -g -x 2>/dev/null | awk '
          $1 == "x" || $2 == "x" { x = $NF }
          $1 == "y" || $2 == "y" { y = $NF }
          $1 == "width" || $2 == "width" { w = $NF }
          $1 == "height" || $2 == "height" { h = $NF }
          END {
            if (w > 0 && h > 0) {
              printf "%s,%s %sx%s focused\n", x, y, w, h
            }
          }
        '
      }

      collect_rects() {
        hyprland_rects && return 0
        sway_rects && return 0
        mango_rects && return 0
        return 1
      }

      select_area() {
        need slurp

        local rects region
        rects="$(collect_rects || true)"
        start_freeze

        if [ -n "$rects" ]; then
          region="$(printf '%s\n' "$rects" | slurp || true)"
        else
          region="$(slurp || true)"
        fi

        if [ -z "$region" ]; then
          fail "Screenshot cancelled"
        fi

        capture_region "$region"
      }

      case "$mode" in
        area)
          select_area
          ;;
        screen)
          capture_screen
          ;;
      esac
    '';
  };
in {
  home.packages = [
    wayScreenshot
  ];
}
