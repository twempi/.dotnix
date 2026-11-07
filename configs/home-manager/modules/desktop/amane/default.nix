{inputs, ...}: {
  # The Amane shell (github:MystiaFin/amane) for Sway: replaces Waybar, Rofi and SwayNC.
  flake.modules.homeManager.amane = {
    config,
    pkgs,
    ...
  }: let
    inherit (pkgs.stdenv.hostPlatform) system;

    # `amane ipc call` is how keybinds and scripts reach the running shell.
    amane = inputs.amane.packages.${system}.default;
    shell = pkgs.callPackage ./_package.nix {amaneSource = inputs.amane;};

    dmenu = pkgs.writeShellApplication {
      name = "amane-dmenu";
      runtimeInputs = [amane pkgs.coreutils];
      text = builtins.readFile ./scripts/dmenu.sh;
    };
  in {
    home.packages = [
      amane
      dmenu

      # The font rofi's theme named, and an outline emoji font: amane draws no color emoji.
      pkgs.nerd-fonts.jetbrains-mono
      pkgs.noto-fonts-monochrome-emoji

      (pkgs.writeShellApplication {
        name = "amane-launcher";
        runtimeInputs = [amane];
        text = ''
          exec amane ipc call launcher
        '';
      })

      (pkgs.writeShellApplication {
        name = "amane-notifications";
        runtimeInputs = [amane];
        text = ''
          exec amane ipc call notifications
        '';
      })

      (pkgs.writeShellApplication {
        name = "amane-power";
        runtimeInputs = [dmenu] ++ (with pkgs; [systemd hyprlock swaylock libnotify alsa-utils coreutils bash]);
        # Only nounset, like the rofi script, so the menu's exit codes reach its case.
        bashOptions = ["nounset"];
        text = builtins.readFile ./scripts/power.sh;
      })

      (pkgs.writeShellApplication {
        name = "amane-wallpaper";
        runtimeInputs = [dmenu] ++ (with pkgs; [awww libnotify findutils coreutils bash]);
        bashOptions = ["nounset"];
        text = builtins.readFile ./scripts/wallpaper.sh;
      })

      (pkgs.writeShellApplication {
        name = "amane-emoji";
        runtimeInputs = [dmenu] ++ (with pkgs; [unicode-emoji wl-clipboard python3 coreutils]);
        text = ''
          choice="$(
            python3 - <<'PY' | amane-dmenu -dmenu -i -p Emoji -theme emoji
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
          menu_exit=$?

          if [ "$menu_exit" -ne 0 ] || [ -z "$choice" ]; then
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
        name = "amane-clipboard";
        runtimeInputs = [dmenu] ++ (with pkgs; [cliphist wl-clipboard]);
        text = ''
          choice="$(cliphist list | amane-dmenu -dmenu -i -p Clipboard)"
          menu_exit=$?

          if [ "$menu_exit" -ne 0 ] || [ -z "$choice" ]; then
            exit 0
          fi

          printf '%s\n' "$choice" | cliphist decode | wl-copy
        '';
      })

      (pkgs.writeShellApplication {
        name = "amane-gpu";
        runtimeInputs = [dmenu] ++ (with pkgs; [supergfxctl libnotify coreutils gnugrep gnused]);
        text = ''
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
        '';
      })
    ];

    # NixOS aliases "Noto Emoji" to the color font, which amane can't draw. Only the
    # emoji picker asks for this family by name, so no other program is affected.
    xdg.configFile."fontconfig/conf.d/50-amane-noto-emoji.conf".text = ''
      <?xml version="1.0"?>
      <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
      <fontconfig>
        <match target="pattern">
          <test name="family" qual="first"><string>Noto Emoji</string></test>
          <edit name="color" mode="assign"><bool>false</bool></edit>
        </match>
      </fontconfig>
    '';

    # The stylix palette; the shell watches this file, so theme-switch recolors it live.
    xdg.configFile."amane-shell/colors".text = let
      inherit (config.lib.stylix) colors;
      slots = ["base00" "base01" "base02" "base03" "base04" "base05" "base06" "base07" "base08" "base09" "base0A" "base0B" "base0C" "base0D" "base0E" "base0F"];
    in
      builtins.concatStringsSep "" (map (slot: "${slot}=#${colors.${slot}}\n") slots);

    # Only Sway runs the shell; Hyprland keeps Noctalia, so there is no D-Bus activation file.
    systemd.user.services.amane-shell = {
      Unit = {
        Description = "Amane shell: bar, launcher, menus, tray and notifications";
        Requisite = ["sway-session.target"];
        PartOf = ["sway-session.target"];
        After = ["sway-session.target"];
      };

      Service = {
        ExecStart = "${shell}/bin/amane-shell";
        Restart = "on-failure";
        RestartSec = 2;
        # Amane checks these before SWAYSOCK, so one left over from a Hyprland session would win.
        UnsetEnvironment = ["HYPRLAND_INSTANCE_SIGNATURE" "NIRI_SOCKET" "MANGO_INSTANCE_SIGNATURE"];
      };

      Install.WantedBy = ["sway-session.target"];
    };
  };
}
