{
  config,
  inputs,
  lib,
  pkgs,
  system,
  ...
}: let
  quickshellPackage = inputs.quickshell.packages.${system}.default;
  wallpaperPickerConfig = pkgs.runCommandLocal "quickshell-wallpaper-picker-config" {} ''
    mkdir -p "$out"
    cp ${./wallpaper-picker/shell.qml} "$out/shell.qml"
    cp ${./wallpaper-picker/WallpaperCard.qml} "$out/WallpaperCard.qml"
    cat > "$out/Style.qml" <<'EOF'
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
    EOF
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
  qsWallpaper = pkgs.writeShellApplication {
    name = "qs-wallpaper";
    runtimeInputs = [
      quickshellPackage
      qsWallpaperApply
      qsWallpaperList
    ];
    text = ''
      exec ${lib.getExe quickshellPackage} --config wallpaper-picker
    '';
  };
in {
  home.packages = [
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
    configs.wallpaper-picker = wallpaperPickerConfig;
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
