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
    runtimeInputs = [
      pkgs.python3
    ];
    text = ''
      detect_hyprland_screen() {
        [ -n "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ] || return 1
        command -v hyprctl >/dev/null || return 1

        local payload
        payload="$(hyprctl monitors -j 2>/dev/null)" || return 1
        QS_FOCUSED_SCREEN_PAYLOAD="$payload" python3 - <<'PY'
      import json
      import os
      import sys

      try:
          monitors = json.loads(os.environ["QS_FOCUSED_SCREEN_PAYLOAD"])
      except Exception:
          raise SystemExit(1)

      for monitor in monitors:
          if monitor.get("focused"):
              name = monitor.get("name")
              if name:
                  print(name)
                  raise SystemExit(0)

      raise SystemExit(1)
      PY
      }

      detect_sway_screen() {
        [ -n "''${SWAYSOCK:-}" ] || return 1
        command -v swaymsg >/dev/null || return 1

        local payload
        payload="$(swaymsg -t get_outputs --raw 2>/dev/null)" || return 1
        QS_FOCUSED_SCREEN_PAYLOAD="$payload" python3 - <<'PY'
      import json
      import os
      import sys

      try:
          outputs = json.loads(os.environ["QS_FOCUSED_SCREEN_PAYLOAD"])
      except Exception:
          raise SystemExit(1)

      for output in outputs:
          if output.get("focused"):
              name = output.get("name")
              if name:
                  print(name)
                  raise SystemExit(0)

      raise SystemExit(1)
      PY
      }

      detect_niri_screen() {
        [ -n "''${NIRI_SOCKET:-}" ] || return 1
        command -v niri >/dev/null || return 1

        local payload
        payload="$(niri msg -j focused-output 2>/dev/null)" || return 1
        QS_FOCUSED_SCREEN_PAYLOAD="$payload" python3 - <<'PY'
      import json
      import os
      import sys

      def find_output_name(value):
          if isinstance(value, dict):
              name = value.get("name")
              if isinstance(name, str) and name:
                  return name

              for key in ("FocusedOutput", "Ok"):
                  child = value.get(key)
                  found = find_output_name(child)
                  if found:
                      return found

              for child in value.values():
                  found = find_output_name(child)
                  if found:
                      return found
          elif isinstance(value, list):
              for child in value:
                  found = find_output_name(child)
                  if found:
                      return found

          return None

      try:
          payload = json.loads(os.environ["QS_FOCUSED_SCREEN_PAYLOAD"])
      except Exception:
          raise SystemExit(1)

      output_name = find_output_name(payload)
      if output_name:
          print(output_name)
          raise SystemExit(0)

      raise SystemExit(1)
      PY
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
  mkQuickshellRunner = {
    name,
    configName,
    runtimeInputs ? [],
    extraScreenExports ? "",
  }:
    pkgs.writeShellApplication {
      inherit name;
      runtimeInputs =
        [
          quickshellPackage
          qsFocusedScreen
        ]
        ++ runtimeInputs;
      text = ''
        if screen="$(qs-focused-screen)"; then
          export QS_TARGET_SCREEN="$screen"
          ${extraScreenExports}
        fi

        exec ${lib.getExe quickshellPackage} --no-duplicate --config ${configName}
      '';
    };
  qsWallpaper = mkQuickshellRunner {
    name = "qs-wallpaper";
    configName = "wallpaper-picker";
    runtimeInputs = [
      qsWallpaperApply
      qsWallpaperList
    ];
    extraScreenExports = ''
      export QS_WALLPAPER_SCREEN="$screen"
    '';
  };
  qsLauncher = mkQuickshellRunner {
    name = "qs-launcher";
    configName = "app-launcher";
  };
  qsPower = mkQuickshellRunner {
    name = "qs-power";
    configName = "power-menu";
    runtimeInputs = [
      qsPowerAction
      qsPowerInfo
    ];
  };
in {
  home.packages = [
    qsFocusedScreen
    qsLauncher
    qsPower
    qsPowerAction
    qsPowerInfo
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
      wallpaper-picker = wallpaperPickerConfig;
    };
    systemd.enable = false;
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
