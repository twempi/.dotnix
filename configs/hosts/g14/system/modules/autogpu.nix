{ pkgs, ... }:
let
  laptopUser = "edward";

  gfxAutoSwitch = pkgs.writeShellScript "gfx-auto-switch" ''
    set -eu

    notify_user() {
      summary="$1"
      body="$2"

      uid="$(${pkgs.coreutils}/bin/id -u ${laptopUser})"
      runtime_dir="/run/user/$uid"
      bus="unix:path=$runtime_dir/bus"

      if [ -S "$runtime_dir/bus" ]; then
        ${pkgs.util-linux}/bin/runuser -u ${laptopUser} -- \
          env XDG_RUNTIME_DIR="$runtime_dir" \
              DBUS_SESSION_BUS_ADDRESS="$bus" \
              ${pkgs.libnotify}/bin/notify-send "$summary" "$body" || true
      fi
    }

    ac_path=""
    for d in /sys/class/power_supply/*; do
      if [ -f "$d/type" ] && [ "$(${pkgs.coreutils}/bin/cat "$d/type")" = "Mains" ]; then
        ac_path="$d"
        break
      fi
    done

    if [ -z "$ac_path" ]; then
      logger -t gfx-auto-switch "No Mains power_supply device found"
      exit 1
    fi

    online="$(${pkgs.coreutils}/bin/cat "$ac_path/online")"
    current="$(${pkgs.supergfxctl}/bin/supergfxctl --get 2>/dev/null || true)"
    pending="$(${pkgs.supergfxctl}/bin/supergfxctl --pend-mode 2>/dev/null || true)"
    action="$(${pkgs.supergfxctl}/bin/supergfxctl --pend-action 2>/dev/null || true)"

    if [ "$online" = "0" ]; then
      if [ "$current" = "Integrated" ]; then
        logger -t gfx-auto-switch "Running on battery, GPU mode already Integrated"
        exit 0
      fi

      if ${pkgs.supergfxctl}/bin/supergfxctl --mode Integrated; then
        new_current="$(${pkgs.supergfxctl}/bin/supergfxctl --get 2>/dev/null || true)"
        new_pending="$(${pkgs.supergfxctl}/bin/supergfxctl --pend-mode 2>/dev/null || true)"
        new_action="$(${pkgs.supergfxctl}/bin/supergfxctl --pend-action 2>/dev/null || true)"

        logger -t gfx-auto-switch "Battery power, requested GPU mode change '$current' -> 'Integrated'"

        if [ "$new_current" = "Integrated" ]; then
          notify_user \
            "GPU mode switched" \
            "Running on battery. Graphics mode changed to Integrated."
        else
          notify_user \
            "GPU mode change requested" \
            "Running on battery. Requested Integrated. Pending mode: $new_pending. Action: $new_action."
        fi

        exit 0
      fi

      logger -t gfx-auto-switch "Failed to switch GPU mode to Integrated"
      exit 1
    fi

    if [ "$current" = "Hybrid" ]; then
      logger -t gfx-auto-switch "AC connected, GPU mode already Hybrid"
      exit 0
    fi

    if [ "$pending" = "Hybrid" ]; then
      notify_user \
        "Hybrid mode pending" \
        "AC connected. Hybrid mode is already pending. Log out to apply."
      logger -t gfx-auto-switch "AC connected, Hybrid already pending; action: $action"
      exit 0
    fi

    notify_user \
      "AC connected" \
      "Hybrid mode is recommended on AC. Run 'supergfxctl --mode Hybrid' and log out to apply."
    logger -t gfx-auto-switch "AC connected; notifying user instead of auto-switching to Hybrid"
  '';
in
{
  systemd.services.gfx-auto-switch = {
    description = "Auto switch supergfxctl mode on AC/Battery changes";
    after = [ "supergfxd.service" ];
    wants = [ "supergfxd.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = gfxAutoSwitch;
    };
    path = with pkgs; [
      coreutils
      util-linux
      systemd
      supergfxctl
      libnotify
    ];
  };

  services.udev.extraRules = ''
    ACTION=="change", SUBSYSTEM=="power_supply", ENV{POWER_SUPPLY_TYPE}=="Mains", TAG+="systemd", ENV{SYSTEMD_WANTS}+="gfx-auto-switch.service"
  '';

  systemd.services.gfx-auto-switch-at-boot = {
    description = "Apply initial GPU mode based on AC state at boot";
    wantedBy = [ "multi-user.target" ];
    after = [ "supergfxd.service" ];
    wants = [ "supergfxd.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = gfxAutoSwitch;
    };
    path = with pkgs; [
      coreutils
      util-linux
      systemd
      supergfxctl
      libnotify
    ];
  };
}
