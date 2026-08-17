{
  inputs,
  pkgs,
  system,
  ...
}: let
  hyprctl = "${inputs.hyprland.packages.${system}.hyprland}/bin/hyprctl";
  swaymsg = "${pkgs.sway}/bin/swaymsg";
  wlrRandr = "${pkgs.wlr-randr}/bin/wlr-randr";
  g14RefreshRate = import ../refresh-rate/package.nix {inherit inputs pkgs system;};

  g14Clamshell = pkgs.writeShellApplication {
    name = "g14-clamshell";

    text = ''
      mode="''${1:-auto}"
      hyprctl_cmd="${hyprctl}"
      swaymsg_cmd="${swaymsg}"
      wlr_randr_cmd="${wlrRandr}"
      internal_outputs=(eDP-1 eDP-2)

      hdmi_connected() {
        local status
        local value

        for status in /sys/class/drm/card*-HDMI-A-*/status; do
          [[ -e "$status" ]] || continue

          value=""
          read -r value < "$status" || true
          if [[ "$value" == "connected" ]]; then
            return 0
          fi
        done

        return 1
      }

      lid_closed() {
        local state
        local value

        for state in /proc/acpi/button/lid/*/state; do
          [[ -e "$state" ]] || continue

          value=""
          read -r value < "$state" || true
          if [[ "$value" == *closed* ]]; then
            return 0
          fi
        done

        return 1
      }

      close_internal_outputs() {
        hdmi_connected || exit 0

        if [[ -n "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
          for output in "''${internal_outputs[@]}"; do
            "$hyprctl_cmd" eval "hl.monitor({ output = '$output', disabled = true })" >/dev/null 2>&1 || true
          done
        elif [[ -n "''${SWAYSOCK:-}" ]]; then
          for output in "''${internal_outputs[@]}"; do
            "$swaymsg_cmd" output "$output" disable >/dev/null 2>&1 || true
          done
        else
          for output in "''${internal_outputs[@]}"; do
            "$wlr_randr_cmd" --output "$output" --off >/dev/null 2>&1 || true
          done
        fi
      }

      open_internal_outputs() {
        if [[ -n "''${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
          for output in "''${internal_outputs[@]}"; do
            "$hyprctl_cmd" eval "hl.monitor({ output = '$output', disabled = false, mode = '2560x1600@60', position = '0x0', scale = 1.5 })" >/dev/null 2>&1 || true
          done
        elif [[ -n "''${SWAYSOCK:-}" ]]; then
          for output in "''${internal_outputs[@]}"; do
            "$swaymsg_cmd" output "$output" enable mode 2560x1600@60.000Hz pos 0 0 scale 1.5 >/dev/null 2>&1 || true
          done
        else
          for output in "''${internal_outputs[@]}"; do
            "$wlr_randr_cmd" --output "$output" --on --mode 2560x1600@60.000Hz --pos 0,0 --scale 1.5 >/dev/null 2>&1 || true
          done
        fi

        "${g14RefreshRate}/bin/g14-refresh-rate" --once
      }

      case "$mode" in
        close)
          close_internal_outputs
          ;;
        open)
          open_internal_outputs
          ;;
        auto)
          if lid_closed && hdmi_connected; then
            close_internal_outputs
          else
            open_internal_outputs
          fi
          ;;
        *)
          printf 'Usage: g14-clamshell close|open|auto\n' >&2
          exit 2
          ;;
      esac
    '';
  };
in {
  home.packages = [
    g14Clamshell
  ];

  wayland.windowManager.hyprland.extraLuaFiles."g14-clamshell".content = ''
    hl.on("hyprland.start", function()
      hl.exec_cmd("${g14Clamshell}/bin/g14-clamshell auto")
    end)

    hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd("${g14Clamshell}/bin/g14-clamshell close"), { locked = true })
    hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd("${g14Clamshell}/bin/g14-clamshell open"), { locked = true })
  '';

  wayland.windowManager.sway.config = {
    startup = [
      {
        command = "${g14Clamshell}/bin/g14-clamshell auto";
        always = true;
      }
    ];

    bindswitches = {
      "lid:on" = {
        locked = true;
        reload = true;
        action = "exec ${g14Clamshell}/bin/g14-clamshell close";
      };

      "lid:off" = {
        locked = true;
        reload = true;
        action = "exec ${g14Clamshell}/bin/g14-clamshell open";
      };
    };
  };

  wayland.windowManager.mango = {
    autostart_sh = ''
      ${g14Clamshell}/bin/g14-clamshell auto &
    '';

    settings.switchbind = [
      "fold,spawn,${g14Clamshell}/bin/g14-clamshell close"
      "unfold,spawn,${g14Clamshell}/bin/g14-clamshell open"
    ];
  };
}
