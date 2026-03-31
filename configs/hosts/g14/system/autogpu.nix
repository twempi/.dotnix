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
      if [ -f "$d/type" ] && [ "$(cat "$d/type")" = "Mains" ]; then
        ac_path="$d"
        break
      fi
    done

    if [ -z "$ac_path" ]; then
      echo "No Mains power_supply device found"
      exit 1
    fi

    online="$(cat "$ac_path/online")"
    current="$(${pkgs.supergfxctl}/bin/supergfxctl --get 2>/dev/null || true)"

    if [ "$online" = "1" ]; then
      target="Hybrid"
      power_text="AC connected"
    else
      target="Integrated"
      power_text="Running on battery"
    fi

    if [ "$current" = "$target" ]; then
      logger -t gfx-auto-switch "$power_text, GPU mode already '$current'"
      exit 0
    fi

    if ${pkgs.supergfxctl}/bin/supergfxctl --mode "$target"; then
      pending_mode="$(${pkgs.supergfxctl}/bin/supergfxctl --pend-mode 2>/dev/null || true)"
      pending_action="$(${pkgs.supergfxctl}/bin/supergfxctl --pend-action 2>/dev/null || true)"
      new_current="$(${pkgs.supergfxctl}/bin/supergfxctl --get 2>/dev/null || true)"

      logger -t gfx-auto-switch "$power_text, requested GPU mode change '$current' -> '$target'"

      if [ "$new_current" = "$target" ]; then
        notify_user \
          "GPU mode switched" \
          "$power_text. Graphics mode changed to $target."
      else
        notify_user \
          "GPU mode change requested" \
          "$power_text. Requested $target. Pending mode: $pending_mode. Action: $pending_action."
      fi
    else
      logger -t gfx-auto-switch "Failed to switch GPU mode '$current' -> '$target'"
      exit 1
    fi
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
