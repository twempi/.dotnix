{pkgs, ...}: let
  g14PowerApply = pkgs.writeShellScriptBin "g14-power-apply" ''
    set -u

    notify=0
    gpu=1

    while [ "$#" -gt 0 ]; do
      case "$1" in
        --notify)
          notify=1
          ;;
        --no-gpu)
          gpu=0
          ;;
        *)
          echo "usage: g14-power-apply [--notify] [--no-gpu]" >&2
          exit 2
          ;;
      esac
      shift
    done

    is_on_ac() {
      for supply in /sys/class/power_supply/*; do
        [ -e "$supply/type" ] || continue
        [ "$(cat "$supply/type" 2>/dev/null)" = "Mains" ] || continue
        [ "$(cat "$supply/online" 2>/dev/null)" = "1" ] && return 0
      done
      return 1
    }

    send_notify() {
      [ "$notify" -eq 1 ] || return 0

      local title="$1"
      local body="$2"
      local uid runtime_dir bus

      uid="$(${pkgs.coreutils}/bin/id -u edward 2>/dev/null)" || return 0
      runtime_dir="/run/user/$uid"
      bus="$runtime_dir/bus"

      [ -S "$bus" ] || return 0

      ${pkgs.util-linux}/bin/runuser -u edward -- \
        ${pkgs.coreutils}/bin/env \
          XDG_RUNTIME_DIR="$runtime_dir" \
          DBUS_SESSION_BUS_ADDRESS="unix:path=$bus" \
          ${pkgs.libnotify}/bin/notify-send "$title" "$body" --app-name="g14-power" \
        >/dev/null 2>&1 || true
    }

    set_epp() {
      local pref="$1"
      local policy epp available

      for policy in /sys/devices/system/cpu/cpufreq/policy*; do
        epp="$policy/energy_performance_preference"
        available="$policy/energy_performance_available_preferences"
        [ -w "$epp" ] || continue
        if [ -r "$available" ] && ! ${pkgs.gnugrep}/bin/grep -qw "$pref" "$available"; then
          continue
        fi
        echo "$pref" > "$epp" 2>/dev/null || true
      done
    }

    current_gfx_mode() {
      ${pkgs.supergfxctl}/bin/supergfxctl -g 2>/dev/null || echo "unknown"
    }

    apply_gfx_mode() {
      local target="$1"
      local mode status pending_action pending_mode output

      output="$(${pkgs.supergfxctl}/bin/supergfxctl --mode "$target" 2>&1)"
      status="$?"
      mode="$(current_gfx_mode)"
      pending_action="$(${pkgs.supergfxctl}/bin/supergfxctl -p 2>/dev/null || true)"
      pending_mode="$(${pkgs.supergfxctl}/bin/supergfxctl -P 2>/dev/null || true)"

      [ "$pending_action" = "No action required" ] && pending_action=""
      [ "$pending_mode" = "None" ] && pending_mode=""

      if [ "$status" -eq 0 ] && [ "$mode" = "$target" ]; then
        send_notify "G14 graphics switched" "Mode is now $mode."
        return 0
      fi

      if [ -n "$pending_action" ] || [ -n "$pending_mode" ]; then
        send_notify \
          "G14 graphics switch pending" \
          "Requested $target; current mode is $mode. Pending action: ''${pending_action:-none}. Pending mode: ''${pending_mode:-none}. Logout or reboot may be needed."
        return 0
      fi

      if [ "$status" -eq 0 ]; then
        send_notify \
          "G14 graphics switch incomplete" \
          "Requested $target; current mode is $mode. Logout or reboot may be needed."
      else
        send_notify \
          "G14 graphics switch failed" \
          "Requested $target; current mode is $mode. ''${output:-No error output.}"
      fi
      return 0
    }

    if is_on_ac; then
      ${pkgs.power-profiles-daemon}/bin/powerprofilesctl set performance >/dev/null 2>&1 || true
      ${pkgs.asusctl}/bin/asusctl profile set performance >/dev/null 2>&1 || true
      set_epp performance
      ${pkgs.ryzenadj}/bin/ryzenadj \
        --stapm-limit=65000 \
        --fast-limit=80000 \
        --slow-limit=65000 \
        --tctl-temp=95 \
        >/dev/null 2>&1 || true

      if [ "$gpu" -eq 1 ]; then
        apply_gfx_mode Hybrid
      elif [ "$notify" -eq 1 ]; then
        send_notify "G14 power profile" "AC performance profile applied."
      fi
    else
      ${pkgs.power-profiles-daemon}/bin/powerprofilesctl set power-saver >/dev/null 2>&1 || true
      ${pkgs.asusctl}/bin/asusctl profile set quiet >/dev/null 2>&1 \
        || ${pkgs.asusctl}/bin/asusctl profile set lowpower >/dev/null 2>&1 \
        || true
      set_epp power
      ${pkgs.ryzenadj}/bin/ryzenadj \
        --stapm-limit=18000 \
        --fast-limit=25000 \
        --slow-limit=18000 \
        --tctl-temp=78 \
        >/dev/null 2>&1 || true

      if [ "$gpu" -eq 1 ]; then
        apply_gfx_mode Integrated
      elif [ "$notify" -eq 1 ]; then
        send_notify "G14 power profile" "Battery power-saving profile applied."
      fi
    fi
  '';
in {
  boot.kernelPackages = pkgs.linuxPackages_latest;

  environment.systemPackages = with pkgs; [
    g14PowerApply
    ryzenadj
  ];

  powerManagement = {
    enable = true;
    cpuFreqGovernor = "powersave";
  };

  services = {
    power-profiles-daemon.enable = true;
    tlp.enable = false;
  };

  hardware.amdgpu.initrd.enable = true;
  programs.corectrl.enable = true;

  users.users.edward.extraGroups = ["corectrl"];

  systemd = {
    services = {
      g14-power-apply = {
        description = "Apply G14 AC/battery power and GPU policy";
        wantedBy = ["multi-user.target"];
        wants = [
          "asusd.service"
          "supergfxd.service"
          "power-profiles-daemon.service"
        ];
        after = [
          "asusd.service"
          "supergfxd.service"
          "power-profiles-daemon.service"
        ];
        before = ["display-manager.service"];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${g14PowerApply}/bin/g14-power-apply";
        };
      };

      g14-power-apply-notify = {
        description = "Apply G14 AC/battery policy and notify user";
        wants = [
          "asusd.service"
          "supergfxd.service"
          "power-profiles-daemon.service"
        ];
        after = [
          "asusd.service"
          "supergfxd.service"
          "power-profiles-daemon.service"
        ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${g14PowerApply}/bin/g14-power-apply --notify";
        };
      };

      g14-power-cpu-apply = {
        description = "Reapply G14 CPU power limits";
        wants = [
          "asusd.service"
          "power-profiles-daemon.service"
        ];
        after = [
          "asusd.service"
          "power-profiles-daemon.service"
        ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${g14PowerApply}/bin/g14-power-apply --no-gpu";
        };
      };

      g14-power-resume = {
        description = "Reapply G14 CPU power policy after resume";
        wantedBy = ["suspend.target"];
        wants = [
          "asusd.service"
          "power-profiles-daemon.service"
        ];
        after = [
          "suspend.target"
          "asusd.service"
          "power-profiles-daemon.service"
        ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${g14PowerApply}/bin/g14-power-apply --no-gpu";
        };
      };
    };

    timers.g14-power-cpu-apply = {
      wantedBy = ["timers.target"];
      timerConfig = {
        OnBootSec = "2min";
        OnUnitActiveSec = "1min";
        Unit = "g14-power-cpu-apply.service";
      };
    };
  };

  services.udev.extraRules = ''
    ACTION=="change", SUBSYSTEM=="power_supply", ATTR{type}=="Mains", TAG+="systemd", ENV{SYSTEMD_WANTS}+="g14-power-apply-notify.service"
  '';

  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchDocked = "ignore";
    HandlePowerKey = "suspend";
    HandlePowerKeyLongPress = "poweroff";
  };
}
