{
  pkgs,
  ...
}: {
  boot.kernelPackages = pkgs.linuxPackages_latest;

  environment.systemPackages = with pkgs; [ryzenadj];

  powerManagement.enable = true;

  services = {
    power-profiles-daemon.enable = true;
    tlp.enable = false;
  };

  hardware.amdgpu.initrd.enable = true;

  systemd.services.ryzenadj-battery-limits = {
    description = "Apply Ryzen power limits on battery";
    unitConfig.ConditionACPower = false;

    serviceConfig = {
      Type = "oneshot";
      ExecStart = ''
        ${pkgs.ryzenadj}/bin/ryzenadj \
          --stapm-limit=23000 \
          --fast-limit=30000 \
          --slow-limit=25000 \
          --tctl-temp=82
      '';
    };
  };

  systemd.services.ryzenadj-ac-limits = {
    description = "Apply Ryzen power limits on AC";
    unitConfig.ConditionACPower = true;

    serviceConfig = {
      Type = "oneshot";
      ExecStart = ''
        ${pkgs.ryzenadj}/bin/ryzenadj \
          --stapm-limit=45000 \
          --fast-limit=65000 \
          --slow-limit=55000 \
          --tctl-temp=95
      '';
    };
  };

  systemd.timers.ryzenadj-battery-limits = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnBootSec = "2min";
      OnUnitInactiveSec = "5min";
      Unit = "ryzenadj-battery-limits.service";
    };
  };

  systemd.timers.ryzenadj-ac-limits = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnBootSec = "2min";
      OnUnitInactiveSec = "5min";
      Unit = "ryzenadj-ac-limits.service";
    };
  };

  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchDocked = "ignore";
    HandlePowerKey = "suspend";
    HandlePowerKeyLongPress = "poweroff";
  };
}
