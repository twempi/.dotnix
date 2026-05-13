{
  config,
  inputs,
  lib,
  pkgs,
  system,
  ...
}: let
  quickshellPackage = inputs.quickshell.packages.${system}.default;
  styleQml = pkgs.writeText "quickshell-style.qml" ''
    import QtQuick

    QtObject {
      readonly property string fontFamily: "JetBrainsMono Nerd Font"
      readonly property color background: "#${config.lib.stylix.colors.base00}"
      readonly property color backgroundAlt: "#${config.lib.stylix.colors.base01}"
      readonly property color foreground: "#${config.lib.stylix.colors.base05}"
      readonly property color foregroundAlt: "#${config.lib.stylix.colors.base06}"
      readonly property color muted: "#${config.lib.stylix.colors.base04}"
      readonly property color border: "#${config.lib.stylix.colors.base03}"
      readonly property color accent: "#${config.lib.stylix.colors.base0A}"
      readonly property color urgent: "#${config.lib.stylix.colors.base08}"
      readonly property color selectedForeground: "#${config.lib.stylix.colors.base00}"
    }
  '';
  wallpaperPickerConfig = pkgs.runCommandLocal "quickshell-wallpaper-picker-config" {} ''
    mkdir -p "$out"
    cp ${./wallpaper-picker/shell.qml} "$out/shell.qml"
    cp ${./wallpaper-picker/WallpaperCard.qml} "$out/WallpaperCard.qml"
    cp ${styleQml} "$out/Style.qml"
  '';
  appLauncherConfig = pkgs.runCommandLocal "quickshell-app-launcher-config" {} ''
    mkdir -p "$out"
    cp ${./app-launcher/shell.qml} "$out/shell.qml"
    cp ${./app-launcher/AppRow.qml} "$out/AppRow.qml"
    cp ${styleQml} "$out/Style.qml"
  '';
  powerMenuConfig = pkgs.runCommandLocal "quickshell-power-menu-config" {} ''
    mkdir -p "$out"
    cp ${./power-menu/shell.qml} "$out/shell.qml"
    cp ${styleQml} "$out/Style.qml"
    cp -r ${./power-menu/icons} "$out/icons"
  '';
  quickActionsConfig = pkgs.runCommandLocal "quickshell-quick-actions-config" {} ''
    mkdir -p "$out"
    cp ${./quick-actions/shell.qml} "$out/shell.qml"
    cp ${./app-launcher/AppRow.qml} "$out/AppRow.qml"
    cp ${./wallpaper-picker/WallpaperCard.qml} "$out/WallpaperCard.qml"
    cp ${styleQml} "$out/Style.qml"
    cp -r ${./power-menu/icons} "$out/icons"
  '';
  topBarConfig = pkgs.runCommandLocal "quickshell-top-bar-config" {} ''
    mkdir -p "$out"
    cp ${./top-bar/shell.qml} "$out/shell.qml"
    cp ${styleQml} "$out/Style.qml"
  '';
  qsWallpaperCache = pkgs.writeShellApplication {
    name = "qs-wallpaper-cache";
    runtimeInputs = with pkgs; [
      coreutils
      imagemagick
      python3
    ];
    text = ''
      exec python3 - "$@" <<'PY'
      import hashlib
      import json
      import os
      import re
      import shutil
      import subprocess
      import sys
      import tempfile
      from pathlib import Path

      extensions = {".jpg", ".jpeg", ".png", ".webp"}
      wallpapers_dir = Path.home() / "Pictures" / "wallpapers"
      cache_home = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache"))
      cache_root = cache_home / "qs-wallpaper-picker"
      thumbnails_dir = cache_root / "thumbnails"
      manifest_path = cache_root / "manifest.json"

      def natural_key(name):
          return [
              int(part) if part.isdigit() else part.lower()
              for part in re.split(r"(\d+)", name)
          ]

      def compact_json(payload):
          return json.dumps(payload, separators=(",", ":"))

      def emit(payload):
          print(compact_json(payload))

      def error_payload(message):
          return {
              "ok": False,
              "error": message,
              "wallpapers": [],
          }

      def wallpaper_paths():
          if not wallpapers_dir.is_dir():
              return None, error_payload(f"wallpaper directory not found: {wallpapers_dir}")

          try:
              paths = [
                  path.resolve()
                  for path in wallpapers_dir.iterdir()
                  if path.is_file() and path.suffix.lower() in extensions
              ]
          except OSError as error:
              return None, error_payload(str(error))

          return sorted(paths, key=lambda path: natural_key(path.name)), None

      def cache_key(path):
          stat = path.stat()
          return hashlib.sha256(
              f"{path}\0{stat.st_size}\0{stat.st_mtime_ns}".encode()
          ).hexdigest()[:32]

      def generate_thumbnail(path, thumb_path):
          thumbnails_dir.mkdir(parents=True, exist_ok=True)
          fd, tmp_name = tempfile.mkstemp(
              prefix=f".{thumb_path.stem}.",
              suffix=".jpg",
              dir=thumbnails_dir,
          )
          os.close(fd)
          tmp_path = Path(tmp_name)

          try:
              subprocess.run(
                  [
                      "magick",
                      str(path),
                      "-auto-orient",
                      "-thumbnail",
                      "420x280^",
                      "-gravity",
                      "center",
                      "-extent",
                      "420x280",
                      "-strip",
                      "-quality",
                      "82",
                      str(tmp_path),
                  ],
                  check=True,
                  stdout=subprocess.DEVNULL,
                  stderr=subprocess.DEVNULL,
              )
              tmp_path.replace(thumb_path)
          except Exception:
              tmp_path.unlink(missing_ok=True)

      def build_manifest():
          paths, error = wallpaper_paths()
          if error is not None:
              cache_root.mkdir(parents=True, exist_ok=True)
              manifest = {"version": 1, **error}
              manifest_path.write_text(compact_json(manifest) + "\n")
              return manifest

          thumbnails_dir.mkdir(parents=True, exist_ok=True)
          wallpapers = []
          expected_thumbnails = set()

          for path in paths:
              key = cache_key(path)
              thumb_path = thumbnails_dir / f"{key}.jpg"
              expected_thumbnails.add(thumb_path.name)

              if not thumb_path.is_file():
                  generate_thumbnail(path, thumb_path)

              wallpapers.append({
                  "name": path.name,
                  "path": str(path),
                  "url": path.as_uri(),
                  "thumbPath": str(thumb_path),
                  "thumbUrl": thumb_path.as_uri(),
              })

          for cached in thumbnails_dir.glob("*.jpg"):
              if cached.name not in expected_thumbnails:
                  cached.unlink(missing_ok=True)

          manifest = {
              "version": 1,
              "ok": True,
              "wallpapers": wallpapers,
          }
          cache_root.mkdir(parents=True, exist_ok=True)
          manifest_path.write_text(compact_json(manifest) + "\n")
          return manifest

      mode = sys.argv[1] if len(sys.argv) > 1 else "list"

      if mode == "clean":
          shutil.rmtree(cache_root, ignore_errors=True)
      elif mode == "warm":
          build_manifest()
      elif mode == "list":
          emit(build_manifest())
      else:
          print("usage: qs-wallpaper-cache [warm|list|clean]", file=sys.stderr)
          raise SystemExit(64)
      PY
    '';
  };
  qsWallpaperList = pkgs.writeShellApplication {
    name = "qs-wallpaper-list";
    runtimeInputs = [
      qsWallpaperCache
    ];
    text = ''
      exec qs-wallpaper-cache list
    '';
  };
  qsWallpaperApply = pkgs.writeShellApplication {
    name = "qs-wallpaper-apply";
    runtimeInputs = with pkgs; [
      awww
      coreutils
      libnotify
    ];
    text = ''
      if [ "$#" -ne 1 ]; then
        echo "usage: qs-wallpaper-apply <path>" >&2
        exit 64
      fi

      wallpapers_dir="$HOME/Pictures/wallpapers"
      if [ ! -d "$wallpapers_dir" ]; then
        echo "wallpaper directory not found: $wallpapers_dir" >&2
        exit 66
      fi

      wallpapers_dir_real="$(realpath -e "$wallpapers_dir")"
      if ! wallpaper_real="$(realpath -e "$1")"; then
        echo "wallpaper not found: $1" >&2
        exit 66
      fi

      case "$wallpaper_real" in
        "$wallpapers_dir_real"/*) ;;
        *)
          echo "wallpaper must be inside $wallpapers_dir" >&2
          exit 65
          ;;
      esac

      filename="''${wallpaper_real##*/}"
      lower_filename="$(printf '%s' "$filename" | tr '[:upper:]' '[:lower:]')"
      case "$lower_filename" in
        *.jpg|*.jpeg|*.png|*.webp) ;;
        *)
          echo "unsupported wallpaper type: $filename" >&2
          exit 65
          ;;
      esac

      if awww img "$wallpaper_real" \
        --transition-type any \
        --transition-duration 2 \
        --transition-step 255 \
        --transition-fps 60; then
        notify-send "Wallpaper Changed" -i "$wallpaper_real" --app-name=awww
      else
        status=$?
        notify-send "Wallpaper Failed" "$filename" --app-name=awww || true
        exit "$status"
      fi
    '';
  };
  qsFocusedScreen = pkgs.writeShellApplication {
    name = "qs-focused-screen";
    runtimeInputs = with pkgs; [
      gawk
      jq
    ];
    text = ''
      detect_hyprland_screen() {
        [ -n "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ] || return 1
        command -v hyprctl >/dev/null || return 1

        local output
        output="$(hyprctl activeworkspace -j 2>/dev/null | jq -er '.monitor // empty')" || return 1
        [ -n "$output" ] || return 1
        printf '%s\n' "$output"
      }

      detect_sway_screen() {
        [ -n "''${SWAYSOCK:-}" ] || return 1
        command -v swaymsg >/dev/null || return 1

        local output
        output="$(swaymsg -t get_outputs --raw 2>/dev/null | jq -er '.[] | select(.focused).name // empty' | head -n 1)" || return 1
        [ -n "$output" ] || return 1
        printf '%s\n' "$output"
      }

      detect_niri_screen() {
        [ -n "''${NIRI_SOCKET:-}" ] || return 1
        command -v niri >/dev/null || return 1

        local output
        output="$(niri msg -j focused-output 2>/dev/null | jq -er '.. | objects | .name? // empty' | head -n 1)" || return 1
        [ -n "$output" ] || return 1
        printf '%s\n' "$output"
      }

      detect_mango_screen() {
        command -v mmsg >/dev/null || return 1

        local output
        output="$(mmsg -g -o 2>/dev/null | awk '$2 == "selmon" && $3 == "1" { print $1; exit }')" || return 1
        [ -n "$output" ] || return 1
        printf '%s\n' "$output"
      }

      detect_focused_screen() {
        detect_hyprland_screen && return 0
        detect_sway_screen && return 0
        detect_niri_screen && return 0
        detect_mango_screen && return 0
        return 1
      }

      if screen="$(detect_focused_screen)"; then
        printf '%s\n' "$screen"
        exit 0
      fi

      exit 1
    '';
  };
  qsFocusedScreenWatch = pkgs.writeShellApplication {
    name = "qs-focused-screen-watch";
    runtimeInputs = with pkgs; [
      coreutils
      jq
      qsFocusedScreen
      socat
    ];
    text = ''
      emit_current_screen() {
        qs-focused-screen 2>/dev/null || true
      }

      watch_hyprland() {
        [ -n "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ] || return 1

        runtime_dir="''${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
        socket="$runtime_dir/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
        [ -S "$socket" ] || return 1

        emit_current_screen
        socat -U - "UNIX-CONNECT:$socket" 2>/dev/null | while IFS= read -r event; do
          case "$event" in
            focusedmon'>>'*)
              monitor="''${event#focusedmon>>}"
              monitor="''${monitor%%,*}"
              [ -n "$monitor" ] && printf '%s\n' "$monitor"
              ;;
            monitoradded*|monitorremoved*)
              emit_current_screen
              ;;
          esac
        done
      }

      watch_sway() {
        [ -n "''${SWAYSOCK:-}" ] || return 1
        command -v swaymsg >/dev/null || return 1

        emit_current_screen
        swaymsg -t subscribe '["workspace","output"]' --raw 2>/dev/null | while IFS= read -r _event; do
          emit_current_screen
        done
      }

      watch_hyprland && exit 0
      watch_sway && exit 0

      emit_current_screen
      exec sleep infinity
    '';
  };
  qsPowerInfo = pkgs.writeShellApplication {
    name = "qs-power-info";
    runtimeInputs = [
      pkgs.python3
    ];
    text = ''
      exec python3 - <<'PY'
      import json
      from pathlib import Path

      def format_uptime(seconds):
          minutes = int(seconds // 60)
          days, minutes = divmod(minutes, 60 * 24)
          hours, minutes = divmod(minutes, 60)

          parts = []
          if days:
              parts.append(f"{days} day" + ("" if days == 1 else "s"))
          if hours:
              parts.append(f"{hours} hour" + ("" if hours == 1 else "s"))
          if minutes or not parts:
              parts.append(f"{minutes} minute" + ("" if minutes == 1 else "s"))
          return ", ".join(parts)

      try:
          host = Path("/proc/sys/kernel/hostname").read_text().strip()
      except Exception:
          host = "Power"

      try:
          uptime_seconds = float(Path("/proc/uptime").read_text().split()[0])
          uptime = format_uptime(uptime_seconds)
      except Exception:
          uptime = "unknown"

      print(json.dumps({"host": host, "uptime": uptime}, separators=(",", ":")))
      PY
    '';
  };
  qsPowerAction = pkgs.writeShellApplication {
    name = "qs-power-action";
    runtimeInputs = with pkgs; [
      alsa-utils
      coreutils
      hyprlock
      libnotify
      systemd
    ];
    text = ''
      if [ "$#" -ne 1 ]; then
        echo "usage: qs-power-action <lock|suspend|logout|reboot|shutdown>" >&2
        exit 64
      fi

      case "$1" in
        lock)
          if command -v hyprlock >/dev/null; then
            hyprlock >/dev/null 2>&1 &
          else
            notify-send "Lock failed" "hyprlock not found"
            exit 69
          fi
          ;;
        suspend)
          if command -v mpc >/dev/null; then
            mpc -q pause 2>/dev/null || true
          fi
          if command -v amixer >/dev/null; then
            amixer set Master mute 2>/dev/null || true
          fi
          systemctl suspend
          ;;
        logout)
          if [ -n "''${SWAYSOCK:-}" ] && command -v swaymsg >/dev/null; then
            swaymsg exit
          elif [ -n "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ] && command -v hyprctl >/dev/null; then
            hyprctl dispatch exit
          elif [ -n "''${NIRI_SOCKET:-}" ] && command -v niri >/dev/null; then
            niri msg action quit
          elif command -v mmsg >/dev/null; then
            mmsg -q
          elif [ "''${DESKTOP_SESSION:-}" = "openbox" ] && command -v openbox >/dev/null; then
            openbox --exit
          elif [ "''${DESKTOP_SESSION:-}" = "bspwm" ] && command -v bspc >/dev/null; then
            bspc quit
          elif [ "''${DESKTOP_SESSION:-}" = "i3" ] && command -v i3-msg >/dev/null; then
            i3-msg exit
          elif [ "''${DESKTOP_SESSION:-}" = "plasma" ] && command -v qdbus >/dev/null; then
            qdbus org.kde.ksmserver /KSMServer logout 0 0 0
          else
            notify-send "Logout failed" "No supported compositor/session detected"
            exit 69
          fi
          ;;
        reboot)
          systemctl reboot
          ;;
        shutdown)
          systemctl poweroff
          ;;
        *)
          echo "unknown power action: $1" >&2
          exit 64
          ;;
      esac
    '';
  };
  qsMangoTags = pkgs.writeShellApplication {
    name = "qs-mango-tags";
    runtimeInputs = with pkgs; [
      python3
    ];
    text = ''
      exec python3 - "$@" <<'PY'
      import json
      import subprocess
      import sys

      screen = sys.argv[1] if len(sys.argv) > 1 else ""
      tags = [
          {"id": i, "name": str(i), "active": False, "occupied": False, "urgent": False}
          for i in range(1, 11)
      ]

      try:
          output = subprocess.check_output(
              ["mmsg", "-g", "-t"],
              stderr=subprocess.DEVNULL,
              text=True,
              timeout=1,
          )
      except Exception:
          print(json.dumps({"tags": tags}, separators=(",", ":")))
          raise SystemExit(0)

      matched = False
      for line in output.splitlines():
          parts = line.split()
          if len(parts) < 6 or parts[1] != "tag":
              continue
          if screen and parts[0] != screen:
              continue
          try:
              index = int(parts[2]) - 1
              state = int(parts[3])
              clients = int(parts[4])
              focused = int(parts[5])
          except ValueError:
              continue
          if 0 <= index < len(tags):
              tags[index]["active"] = bool(state & 1 or focused)
              tags[index]["occupied"] = clients > 0
              tags[index]["urgent"] = bool(state & 2)
              matched = True

      if screen and not matched:
          for line in output.splitlines():
              parts = line.split()
              if len(parts) < 6 or parts[1] != "tag":
                  continue
              try:
                  index = int(parts[2]) - 1
                  state = int(parts[3])
                  clients = int(parts[4])
                  focused = int(parts[5])
              except ValueError:
                  continue
              if 0 <= index < len(tags):
                  tags[index]["active"] = bool(state & 1 or focused)
                  tags[index]["occupied"] = clients > 0
                  tags[index]["urgent"] = bool(state & 2)

      print(json.dumps({"tags": tags}, separators=(",", ":")))
      PY
    '';
  };
  qsMangoTag = pkgs.writeShellApplication {
    name = "qs-mango-tag";
    runtimeInputs = with pkgs; [
      coreutils
    ];
    text = ''
      if [ "$#" -ne 1 ]; then
        echo "usage: qs-mango-tag <tag>" >&2
        exit 64
      fi

      exec mmsg -t "$1"
    '';
  };
  qsAudioStatus = pkgs.writeShellApplication {
    name = "qs-audio-status";
    runtimeInputs = with pkgs; [
      python3
      wireplumber
    ];
    text = ''
      exec python3 - <<'PY'
      import json
      import re
      import subprocess

      payload = {"text": "VOL --", "percent": 0, "muted": False}
      try:
          output = subprocess.check_output(
              ["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"],
              stderr=subprocess.DEVNULL,
              text=True,
              timeout=1,
          )
          muted = "MUTED" in output
          match = re.search(r"([0-9]+(?:\.[0-9]+)?)", output)
          percent = int(round(float(match.group(1)) * 100)) if match else 0
          icon = "󰝟" if muted else ("󰕿" if percent < 35 else ("󰖀" if percent < 70 else "󰕾"))
          payload = {"text": f"{percent}% {icon}", "percent": percent, "muted": muted}
      except Exception:
          pass

      print(json.dumps(payload, separators=(",", ":")))
      PY
    '';
  };
  qsBacklightStatus = pkgs.writeShellApplication {
    name = "qs-backlight-status";
    runtimeInputs = with pkgs; [
      brightnessctl
      python3
    ];
    text = ''
      exec python3 - <<'PY'
      import json
      import re
      import subprocess

      payload = {"text": "", "visible": False, "percent": 0}
      try:
          output = subprocess.check_output(
              ["brightnessctl", "-m"],
              stderr=subprocess.DEVNULL,
              text=True,
              timeout=1,
          ).strip()
          match = re.search(r",([0-9]+)%", output)
          percent = int(match.group(1)) if match else 0
          icon = "󰃞" if percent < 35 else ("󰃟" if percent < 70 else "󰃠")
          payload = {"text": f"{icon} {percent}% |", "visible": True, "percent": percent}
      except Exception:
          pass

      print(json.dumps(payload, separators=(",", ":")))
      PY
    '';
  };
  qsBatteryStatus = pkgs.writeShellApplication {
    name = "qs-battery-status";
    runtimeInputs = with pkgs; [
      python3
    ];
    text = ''
      exec python3 - <<'PY'
      import json
      from pathlib import Path

      batteries = sorted(Path("/sys/class/power_supply").glob("BAT*"))
      if not batteries:
          print(json.dumps({"visible": False, "text": ""}, separators=(",", ":")))
          raise SystemExit(0)

      battery = batteries[0]
      try:
          capacity = int((battery / "capacity").read_text().strip())
      except Exception:
          capacity = 0
      try:
          status = (battery / "status").read_text().strip()
      except Exception:
          status = "Unknown"

      if status in {"Charging", "Full"}:
          icon = ""
      elif capacity < 15:
          icon = ""
      elif capacity < 35:
          icon = ""
      elif capacity < 60:
          icon = ""
      elif capacity < 85:
          icon = ""
      else:
          icon = ""

      print(json.dumps({
          "visible": True,
          "text": f"{icon} {capacity}% |",
          "capacity": capacity,
          "status": status,
      }, separators=(",", ":")))
      PY
    '';
  };
  qsNotificationStatus = pkgs.writeShellApplication {
    name = "qs-notification-status";
    runtimeInputs = with pkgs; [
      python3
      swaynotificationcenter
    ];
    text = ''
      exec python3 - <<'PY'
      import json
      import subprocess

      count = 0
      dnd = False
      try:
          count = int(subprocess.check_output(
              ["swaync-client", "-c"],
              stderr=subprocess.DEVNULL,
              text=True,
              timeout=1,
          ).strip() or "0")
      except Exception:
          pass
      try:
          dnd_text = subprocess.check_output(
              ["swaync-client", "-D"],
              stderr=subprocess.DEVNULL,
              text=True,
              timeout=1,
          ).strip().lower()
          dnd = dnd_text in {"true", "1", "yes", "on", "dnd"}
      except Exception:
          pass

      icon = "" if dnd else ""
      marker = " " if count > 0 else ""
      print(json.dumps({"text": f"{icon}{marker}", "count": count, "dnd": dnd}, separators=(",", ":")))
      PY
    '';
  };
  qsPanelInfo = pkgs.writeShellApplication {
    name = "qs-panel-info";
    runtimeInputs = with pkgs; [
      coreutils
      iproute2
      networkmanager
      playerctl
      python3
      wireplumber
      wlr-randr
    ];
    text = ''
      exec python3 - "$@" <<'PY'
      import calendar
      import json
      import os
      import re
      import socket
      import subprocess
      import sys
      from datetime import datetime
      from pathlib import Path

      kind = sys.argv[1] if len(sys.argv) > 1 else ""

      def run(command):
          try:
              return subprocess.check_output(command, stderr=subprocess.DEVNULL, text=True, timeout=1).strip()
          except Exception:
              return ""

      def payload(title, subtitle="", rows=None, actions=None, error=""):
          print(json.dumps({
              "title": title,
              "subtitle": subtitle,
              "rows": rows or [],
              "actions": actions or [],
              "error": error,
          }, separators=(",", ":")))

      def audio():
          output = run(["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"])
          muted = "MUTED" in output
          match = re.search(r"([0-9]+(?:\.[0-9]+)?)", output)
          percent = int(round(float(match.group(1)) * 100)) if match else 0
          rows = [
              {"label": "Output", "value": f"{percent}%"},
              {"label": "Muted", "value": "Yes" if muted else "No"},
          ]
          payload("Volume", "Default audio sink", rows, [
              {"label": "Down", "action": "volume-down"},
              {"label": "Mute", "action": "volume-mute"},
              {"label": "Up", "action": "volume-up"},
          ])

      def music():
          title = run(["playerctl", "metadata", "title"]) or "No active player"
          artist = run(["playerctl", "metadata", "artist"])
          status = run(["playerctl", "status"]) or "Stopped"
          player = run(["playerctl", "-l"]).splitlines()
          rows = [
              {"label": "Track", "value": title},
              {"label": "Artist", "value": artist or "Unknown"},
              {"label": "Status", "value": status},
              {"label": "Players", "value": ", ".join(player) if player else "None"},
          ]
          payload("Music", status, rows, [
              {"label": "Prev", "action": "music-prev"},
              {"label": "Play", "action": "music-toggle"},
              {"label": "Next", "action": "music-next"},
          ])

      def battery():
          batteries = sorted(Path("/sys/class/power_supply").glob("BAT*"))
          if not batteries:
              payload("Battery", "No battery detected", [{"label": "Power", "value": "AC or desktop"}])
              return
          bat = batteries[0]
          rows = []
          for name in ["capacity", "status", "health", "manufacturer", "model_name"]:
              path = bat / name
              if path.exists():
                  try:
                      rows.append({"label": name.replace("_", " ").title(), "value": path.read_text().strip()})
                  except Exception:
                      pass
          payload("Battery", bat.name, rows)

      def calendar_panel():
          now = datetime.now()
          weeks = calendar.monthcalendar(now.year, now.month)
          rows = []
          for week in weeks:
              rows.append({
                  "label": "Week",
                  "value": " ".join("--" if day == 0 else (f"[{day:02d}]" if day == now.day else f"{day:02d}") for day in week),
              })
          payload("Calendar", now.strftime("%B %Y"), rows)

      def network():
          nm = run(["nmcli", "-t", "-f", "DEVICE,TYPE,STATE,CONNECTION", "device", "status"])
          rows = []
          for line in nm.splitlines():
              parts = line.split(":")
              if len(parts) >= 4 and parts[2] == "connected":
                  rows.append({"label": parts[0], "value": f"{parts[1]}: {parts[3]}"})
          route = run(["ip", "-brief", "addr", "show", "scope", "global"])
          for line in route.splitlines()[:4]:
              bits = line.split()
              if len(bits) >= 3:
                  rows.append({"label": bits[0], "value": " ".join(bits[2:])})
          payload("Network", "Connected devices" if rows else "No active connection", rows, [
              {"label": "Refresh", "action": "network-refresh"},
          ])

      def monitors():
          output = run(["mmsg", "-g", "-O"]) or run(["wlr-randr"])
          rows = []
          for line in output.splitlines():
              line = line.strip()
              if not line:
                  continue
              rows.append({"label": "Output", "value": line})
          payload("Monitors", "Mango outputs", rows or [{"label": "Outputs", "value": "Unavailable"}])

      def guide():
          rows = [
              ("SUPER+Return", "Terminal"),
              ("SUPER+B", "Browser"),
              ("SUPER+Space", "Launcher"),
              ("SUPER+Q", "Close focused window"),
              ("SUPER+SHIFT+Q", "Force kill focused window"),
              ("SUPER+F", "Maximize"),
              ("SUPER+SHIFT+F", "Fullscreen"),
              ("SUPER+H/J/K/L", "Move focus"),
              ("SUPER+CTRL+H/J/K/L", "Swap windows"),
              ("SUPER+SHIFT+H/J/K/L", "Resize window"),
              ("SUPER+1..9,0", "View tags 1-10"),
              ("SUPER+SHIFT+1..9,0", "Move window to tags 1-10"),
              ("SUPER+ALT+V", "Volume panel"),
              ("SUPER+ALT+G", "This guide"),
          ]
          payload("Guide", "Mango keybinds", [{"label": key, "value": value} for key, value in rows])

      def focustime():
          payload("Focus Time", "25 minute local timer", [
              {"label": "Mode", "value": "Pomodoro"},
              {"label": "Duration", "value": "25 minutes"},
          ], [
              {"label": "Start", "action": "focus-toggle"},
              {"label": "Reset", "action": "focus-reset"},
          ])

      def stewart():
          uptime = "unknown"
          try:
              seconds = float(Path("/proc/uptime").read_text().split()[0])
              hours = int(seconds // 3600)
              minutes = int((seconds % 3600) // 60)
              uptime = f"{hours}h {minutes}m"
          except Exception:
              pass
          rows = [
              {"label": "Host", "value": socket.gethostname()},
              {"label": "User", "value": os.environ.get("USER", "edward")},
              {"label": "Uptime", "value": uptime},
          ]
          payload("System", "Quick actions", rows, [
              {"label": "Launcher", "action": "open-launcher"},
              {"label": "Wallpaper", "action": "open-wallpaper"},
              {"label": "Power", "action": "open-power"},
              {"label": "Reload", "action": "reload-mango"},
              {"label": "Restart", "action": "restart-shell"},
          ])

      handlers = {
          "volume": audio,
          "music": music,
          "battery": battery,
          "calendar": calendar_panel,
          "network": network,
          "monitors": monitors,
          "guide": guide,
          "focustime": focustime,
          "stewart": stewart,
      }

      if kind in handlers:
          handlers[kind]()
      else:
          payload("Panel", error=f"Unknown panel: {kind}")
      PY
    '';
  };
  qsQuickAction = pkgs.writeShellApplication {
    name = "qs-quick-action";
    runtimeInputs = with pkgs; [
      coreutils
      libnotify
      quickshellPackage
      systemd
    ];
    text = ''
      if [ "$#" -ne 1 ]; then
        echo "usage: qs-quick-action <launcher|power|wallpaper|monitors|stewart|music|battery|calendar|network|focustime|volume|guide>" >&2
        exit 64
      fi

      kind="$1"
      case "$kind" in
        launcher|power|wallpaper|monitors|stewart|music|battery|calendar|network|focustime|volume|guide) ;;
        *)
          echo "unknown quick action: $kind" >&2
          exit 64
          ;;
      esac

      call_ipc() {
        ${lib.getExe quickshellPackage} ipc --config quick-actions call quick-actions activate "$kind" >/dev/null 2>&1
      }

      if call_ipc; then
        exit 0
      fi

      systemctl --user start qs-quick-actions.service >/dev/null 2>&1 || true

      attempt=0
      while [ "$attempt" -lt 20 ]; do
        sleep 0.05
        if call_ipc; then
          exit 0
        fi
        attempt=$((attempt + 1))
      done

      notify-send "Quickshell" "Could not open $kind" --app-name=quickshell || true
      exit 1
    '';
  };
  qsPanelAction = pkgs.writeShellApplication {
    name = "qs-panel-action";
    runtimeInputs = with pkgs; [
      coreutils
      libnotify
      playerctl
      qsQuickAction
      swaynotificationcenter
      systemd
      wireplumber
    ];
    text = ''
      if [ "$#" -ne 1 ]; then
        echo "usage: qs-panel-action <action>" >&2
        exit 64
      fi

      case "$1" in
        music-prev)
          playerctl previous
          ;;
        music-toggle)
          playerctl play-pause
          ;;
        music-next)
          playerctl next
          ;;
        volume-down)
          wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
          ;;
        volume-up)
          wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+
          ;;
        volume-mute)
          wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
          ;;
        network-refresh)
          :
          ;;
        open-launcher)
          qs-quick-action launcher
          ;;
        open-wallpaper)
          qs-quick-action wallpaper
          ;;
        open-power)
          qs-quick-action power
          ;;
        reload-mango)
          mmsg -d reload_config || true
          systemctl --user restart qs-top-bar.service qs-quick-actions.service || true
          swaync-client -R 2>/dev/null || true
          ;;
        restart-shell)
          systemctl --user restart qs-top-bar.service qs-quick-actions.service
          ;;
        *)
          notify-send "Quickshell" "Unknown action: $1" --app-name=quickshell || true
          exit 64
          ;;
      esac
    '';
  };
  qsManager = pkgs.writeShellApplication {
    name = "qs-manager";
    runtimeInputs = [
      qsQuickAction
    ];
    text = ''
      if [ "$#" -eq 1 ]; then
        exec qs-quick-action "$1"
      fi

      if [ "$#" -eq 2 ]; then
        case "$1" in
          toggle|open)
            exec qs-quick-action "$2"
            ;;
        esac
      fi

      echo "usage: qs-manager [toggle|open] <kind>" >&2
      exit 64
    '';
  };
  qsWallpaper = pkgs.writeShellApplication {
    name = "qs-wallpaper";
    runtimeInputs = [
      qsQuickAction
    ];
    text = ''
      exec qs-quick-action wallpaper
    '';
  };
  qsLauncher = pkgs.writeShellApplication {
    name = "qs-launcher";
    runtimeInputs = [
      qsQuickAction
    ];
    text = ''
      exec qs-quick-action launcher
    '';
  };
  qsPower = pkgs.writeShellApplication {
    name = "qs-power";
    runtimeInputs = [
      qsQuickAction
    ];
    text = ''
      exec qs-quick-action power
    '';
  };
in {
  home.packages = [
    qsAudioStatus
    qsBacklightStatus
    qsBatteryStatus
    qsFocusedScreen
    qsFocusedScreenWatch
    qsLauncher
    qsMangoTag
    qsMangoTags
    qsManager
    qsNotificationStatus
    qsPanelAction
    qsPanelInfo
    qsPower
    qsPowerAction
    qsPowerInfo
    qsQuickAction
    qsWallpaper
    qsWallpaperApply
    qsWallpaperCache
    qsWallpaperList
  ];

  home.activation.qsWallpaperThumbnailCache = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ${lib.getExe qsWallpaperCache} warm || true
  '';

  programs.quickshell = {
    enable = true;
    package = quickshellPackage;
    configs = {
      app-launcher = appLauncherConfig;
      power-menu = powerMenuConfig;
      quick-actions = quickActionsConfig;
      top-bar = topBarConfig;
      wallpaper-picker = wallpaperPickerConfig;
    };
    systemd.enable = false;
  };

  systemd.user.services.qs-quick-actions = {
    Unit = {
      Description = "Resident Quickshell quick action overlays";
    };

    Service = {
      ExecStart = "${lib.getExe quickshellPackage} --config quick-actions";
      Restart = "on-failure";
      RestartSec = 1;
      Environment = [
        "PATH=${lib.makeBinPath [
          qsPowerAction
          qsPowerInfo
          qsFocusedScreenWatch
          qsPanelAction
          qsPanelInfo
          qsManager
          qsWallpaperApply
          qsWallpaperList
          pkgs.iproute2
          pkgs.networkmanager
          pkgs.playerctl
          pkgs.swaynotificationcenter
          pkgs.systemd
          pkgs.wireplumber
          pkgs.wlr-randr
          pkgs.coreutils
        ]}:${config.home.profileDirectory}/bin:/run/current-system/sw/bin"
      ];
    };

    Install.WantedBy = [config.wayland.systemd.target];
  };

  systemd.user.services.qs-top-bar = {
    Unit = {
      Description = "Quickshell Mango top bar";
    };

    Service = {
      ExecStart = "${lib.getExe quickshellPackage} --config top-bar";
      Restart = "on-failure";
      RestartSec = 1;
      Environment = [
        "PATH=${lib.makeBinPath [
          qsAudioStatus
          qsBacklightStatus
          qsBatteryStatus
          qsMangoTag
          qsMangoTags
          qsManager
          qsNotificationStatus
          pkgs.brightnessctl
          pkgs.coreutils
          pkgs.swaynotificationcenter
          pkgs.wireplumber
        ]}:${config.home.profileDirectory}/bin:/run/current-system/sw/bin"
      ];
    };

    Install.WantedBy = [config.wayland.systemd.target];
  };

  systemd.user.services.qs-wallpaper-cache = {
    Unit = {
      Description = "Warm Quickshell wallpaper thumbnail cache";
    };

    Service = {
      Type = "oneshot";
      ExecStart = "${lib.getExe qsWallpaperCache} warm";
    };

    Install.WantedBy = [config.wayland.systemd.target];
  };
}
