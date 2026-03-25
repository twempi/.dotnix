{pkgs, ...}: let
  autoGpuMode = pkgs.writeShellApplication {
    name = "auto-gpu-mode";
    runtimeInputs = with pkgs; [
      bash
      coreutils
      gnugrep
      gnused
      systemd
      supergfxctl
    ];
    text = ''
      set -euo pipefail

      log() {
        systemd-cat -t auto-gpu-mode echo "$*"
      }

      # Find AC adapter state from /sys/class/power_supply
      ac_online="0"
      for f in /sys/class/power_supply/*/type; do
        [ -e "$f" ] || continue
        if grep -qx "Mains" "$f"; then
          dir="$(dirname "$f")"
          if [ -r "$dir/online" ]; then
            ac_online="$(cat "$dir/online")"
            break
          fi
        fi
      done

      supported="$(supergfxctl --supported 2>/dev/null || true)"
      current="$(supergfxctl --get 2>/dev/null || true)"

      if [ "$ac_online" = "1" ]; then
        # Plugged in: prefer full dGPU mode if supported, otherwise Hybrid.
        if echo "$supported" | grep -q "AsusMuxDgpu"; then
          target="AsusMuxDgpu"
        elif echo "$supported" | grep -q "Hybrid"; then
          target="Hybrid"
        else
          log "AC detected, but no usable dGPU-capable mode found. Supported: $supported"
          exit 0
        fi
      else
        # Battery: prefer iGPU-only
        if echo "$supported" | grep -q "Integrated"; then
          target="Integrated"
        else
          log "Battery detected, but Integrated mode is not supported. Supported: $supported"
          exit 0
        fi
      fi

      if [ "$current" = "$target" ]; then
        log "GPU mode already $target"
        exit 0
      fi

      log "Switching GPU mode from '$current' to '$target'"
      supergfxctl --mode "$target" || {
        log "Failed to request GPU mode change to $target"
        exit 1
      }

      pending_action="$(supergfxctl --pend-action 2>/dev/null || true)"
      pending_mode="$(supergfxctl --pend-mode 2>/dev/null || true)"

      if [ -n "$pending_action" ] || [ -n "$pending_mode" ]; then
        log "Pending action after mode switch. action='$pending_action' mode='$pending_mode'"
      else
        log "GPU mode switch request completed with no pending action reported"
      fi
    '';
  };
in {
  environment.systemPackages = [autoGpuMode];

  systemd.services.auto-gpu-mode = {
    description = "Auto switch ASUS GPU mode on AC adapter changes";
    after = ["supergfxd.service"];
    wants = ["supergfxd.service"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${autoGpuMode}/bin/auto-gpu-mode";
    };
  };

  # Run once at boot so the mode matches the current power source
  systemd.services.auto-gpu-mode-on-boot = {
    description = "Set ASUS GPU mode at boot based on AC state";
    after = ["multi-user.target" "supergfxd.service"];
    wants = ["supergfxd.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${autoGpuMode}/bin/auto-gpu-mode";
    };
  };

  # Trigger when AC adapter status changes
  services.udev.extraRules = ''
    ACTION=="change", SUBSYSTEM=="power_supply", ATTR{type}=="Mains", TAG+="systemd", ENV{SYSTEMD_WANTS}+="auto-gpu-mode.service"
  '';
}
