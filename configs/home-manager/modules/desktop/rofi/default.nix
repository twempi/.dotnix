{
  pkgs,
  config,
  ...
}: let
  rofiConfig = "${config.xdg.configHome}/rofi/config.rasi";
in {
  stylix.targets.rofi.enable = true;
  home.file.".config/rofi/config.rasi".source = ./config.rasi;
  # home.file.".config/rofi/theme.rasi".source = ./theme.rasi;

  /*
    Superseded by Noctalia shell panels.
  home.file.".config/rofi/scripts/wallpaper.sh" = {
    source = ./wallpaper/wallpaper.sh; # keep your repo path here
    executable = true;
  };
  home.file.".config/rofi/themes/wallpaper.rasi".source = ./wallpaper/wallpaper.rasi;

  home.file.".config/rofi/scripts/powermenu.sh" = {
    source = ./powermenu/powermenu.sh; # <-- your repo path
    executable = true;
  };
  home.file.".config/rofi/themes/powermenu.rasi".source = ./powermenu/powermenu.rasi;
  */

  home.file.".config/rofi/theme.rasi".text = ''
    * {
      font: "JetBrainsMono Nerd Font 11";

      background:        #${config.lib.stylix.colors.base00};
      background-alt:    #${config.lib.stylix.colors.base01};
      foreground:        #${config.lib.stylix.colors.base05};
      foreground-alt:    #${config.lib.stylix.colors.base06};
      border:            #${config.lib.stylix.colors.base03};
      active:            #${config.lib.stylix.colors.base0A};
      urgent:            #${config.lib.stylix.colors.base08};

      selected:          @active;

      border-colour:               @selected;
      handle-colour:               @selected;
      background-colour:           @background;
      foreground-colour:           @foreground;
      alternate-background:        @background-alt;

      normal-background:           @background;
      normal-foreground:           @foreground;

      urgent-background:           @urgent;
      urgent-foreground:           @background;

      active-background:           @active;
      active-foreground:           @background;

      selected-normal-background:  @selected;
      selected-normal-foreground:  @background;

      selected-urgent-background:  @active;
      selected-urgent-foreground:  @background;

      selected-active-background:  @urgent;
      selected-active-foreground:  @background;

      alternate-normal-background: @background;
      alternate-normal-foreground: @foreground;

      alternate-urgent-background: @urgent;
      alternate-urgent-foreground: @background;

      alternate-active-background: @active;
      alternate-active-foreground: @background;
    }
  '';

  home.packages = [
    /*
      Superseded by Noctalia shell panels.
    (pkgs.writeShellApplication {
      name = "rofi-launcher";
      runtimeInputs = with pkgs; [
        rofi
      ];
      text = ''
        exec rofi -show drun -theme "${rofiConfig}"
      '';
    })

    (pkgs.writeShellApplication {
      name = "rofi-wallpaper";
      runtimeInputs = with pkgs; [
        rofi
        awww
        libnotify
        findutils
        coreutils
        bash
      ];
      text = ''
        exec "${config.xdg.configHome}/rofi/scripts/wallpaper.sh"
      '';
    })

    (pkgs.writeShellApplication {
      name = "rofi-power";
      runtimeInputs = with pkgs; [
        rofi
        systemd
        hyprlock
        libnotify
        alsa-utils
        coreutils
        bash
      ];
      text = ''
        exec "${config.xdg.configHome}/rofi/scripts/powermenu.sh"
      '';
    })

    (pkgs.writeShellApplication {
      name = "rofi-emoji";
      runtimeInputs = with pkgs; [
        rofi
        unicode-emoji
        wl-clipboard
        python3
        coreutils
      ];
      text = ''
        theme="${rofiConfig}"

        choice="$(
          python3 - <<'PY' | rofi -dmenu -i -p Emoji -theme "$theme"
        import os
        import re
        from pathlib import Path

        unicode_emoji_test = Path("${pkgs.unicode-emoji}/share/unicode/emoji/emoji-test.txt")

        def read_lines(path):
            try:
                return path.read_text(encoding="utf-8", errors="ignore").splitlines()
            except OSError:
                return []

        def plain_item(raw):
            line = raw.strip()
            if not line or line.startswith("#"):
                return None
            return line

        def unicode_item(raw):
            if "#" not in raw or "; fully-qualified" not in raw:
                return None
            comment = raw.split("#", 1)[1].strip()
            match = re.match(r"(\S+)\s+E[0-9.]+\s+(.+)$", comment)
            if not match:
                return None
            value, description = match.groups()
            return f"{value} {description}"

        def parse_item(raw):
            return unicode_item(raw) or plain_item(raw)

        def emoji_source_lines():
            custom = os.environ.get("BEMOJI_CUSTOM_LIST")
            if custom:
                custom_path = Path(custom).expanduser()
                if custom_path.is_file():
                    return read_lines(custom_path)

            data_home = Path(os.environ.get("XDG_DATA_HOME", Path.home() / ".local" / "share"))
            database = Path(os.environ.get("BEMOJI_DB_LOCATION", data_home / "bemoji")).expanduser()
            lines = []
            if database.is_dir():
                for path in sorted(database.glob("*.txt")):
                    if path.is_file():
                        lines.extend(read_lines(path))
            if lines:
                return lines

            return read_lines(unicode_emoji_test)

        def history_lines():
            state_home = Path(os.environ.get("XDG_STATE_HOME", Path.home() / ".local" / "state"))
            history_dir = Path(os.environ.get("BEMOJI_HISTORY_LOCATION", state_home)).expanduser()
            history_file = history_dir / "bemoji-history.txt"
            counts = {}
            order = []

            for raw in read_lines(history_file):
                line = raw.strip()
                if not line:
                    continue
                if line not in counts:
                    counts[line] = 0
                    order.append(line)
                counts[line] += 1

            return sorted(order, key=lambda line: (-counts[line], order.index(line)))

        seen = set()
        for raw in history_lines() + emoji_source_lines():
            item = parse_item(raw)
            if item is None or item in seen:
                continue
            seen.add(item)
            print(item)
        PY
        )"
        rofi_exit=$?

        if [ "$rofi_exit" -ne 0 ] || [ -z "$choice" ]; then
          exit 0
        fi

        value="$(python3 - "$choice" <<'PY'
        import sys

        line = sys.argv[1].strip()
        print(line.split(None, 1)[0] if line else "")
        PY
        )"

        if [ -z "$value" ]; then
          exit 0
        fi

        printf '%s' "$value" | wl-copy

        history_dir="''${BEMOJI_HISTORY_LOCATION:-''${XDG_STATE_HOME:-$HOME/.local/state}}"
        mkdir -p "$history_dir"
        printf '%s\n' "$choice" >> "$history_dir/bemoji-history.txt"
      '';
    })

    (pkgs.writeShellApplication {
      name = "rofi-clipboard";
      runtimeInputs = with pkgs; [
        rofi
        cliphist
        wl-clipboard
      ];
      text = ''
        choice="$(cliphist list | rofi -dmenu -i -p Clipboard -theme "${rofiConfig}")"
        rofi_exit=$?

        if [ "$rofi_exit" -ne 0 ] || [ -z "$choice" ]; then
          exit 0
        fi

        printf '%s\n' "$choice" | cliphist decode | wl-copy
      '';
    })
    */

    (pkgs.writeShellApplication {
      name = "rofi-gpu";
      runtimeInputs = with pkgs; [
        rofi
        supergfxctl
        libnotify
        coreutils
        gnugrep
        gnused
      ];
      text = ''
        theme="${rofiConfig}"

        notify() {
          notify-send "$1" "$2" --app-name=rofi-gpu 2>/dev/null || true
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

        choice="$(printf '%s' "$options" | rofi -dmenu -i -p "GPU: $current" -theme "$theme")"
        rofi_exit=$?

        if [ "$rofi_exit" -ne 0 ] || [ -z "$choice" ]; then
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
      '';
    })
  ];
}
