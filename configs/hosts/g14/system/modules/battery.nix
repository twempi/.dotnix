{pkgs, ...}: {
  boot.kernelPackages = pkgs.linuxPackages_latest;

  environment.systemPackages = with pkgs; [ryzenadj];

  powerManagement.enable = true;

  services = {
    power-profiles-daemon.enable = true;
    tlp.enable = false;
  };

  hardware.amdgpu.initrd.enable = true;
  programs.corectrl.enable = true;

  users.users.edward.extraGroups = ["corectrl"];

  systemd.services.ryzenadj-battery-limits = {
    description = "Apply Ryzen power limits on battery only";
    wantedBy = ["multi-user.target"];
    after = ["multi-user.target"];

    unitConfig = {
      ConditionACPower = false;
    };

    serviceConfig = {
      Type = "oneshot";
      ExecStart = ''
        ${pkgs.ryzenadj}/bin/ryzenadj \
          --stapm-limit=20000 \
          --fast-limit=24000 \
          --slow-limit=22000 \
          --tctl-temp=80
      '';
    };
  };

  systemd.timers.ryzenadj-battery-limits = {
    wantedBy = ["timers.target"];
    timerConfig = {
      OnBootSec = "2min";
      OnUnitActiveSec = "1min";
      Unit = "ryzenadj-battery-limits.service";
    };
  };

  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchDocked = "ignore";
    HandlePowerKey = "suspend";
    HandlePowerKeyLongPress = "poweroff";
  };
}
