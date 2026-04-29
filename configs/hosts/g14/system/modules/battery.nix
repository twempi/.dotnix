{pkgs, ...}: {
  boot.kernelPackages = pkgs.linuxPackages_latest;

  environment.systemPackages = with pkgs; [ryzenadj];

  powerManagement.enable = true;

  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 32 * 1024; # 32 GiB, size is in MiB
    }
  ];

  # Device containing the swapfile
  boot.resumeDevice = "/dev/disk/by-uuid/dc1a523c-a254-4179-8ae0-09eea89e2694";

  # Add this only after you calculate the real offset
  # boot.kernelParams = [ "resume_offset=PUT_REAL_OFFSET_HERE" ];

  services = {
    power-profiles-daemon.enable = true;
    tlp.enable = false;

    logind.settings.Login = {
      HandleLidSwitch = "suspend-then-hibernate";
      HandleLidSwitchDocked = "ignore";
      HandlePowerKey = "suspend";
      HandlePowerKeyLongPress = "poweroff";
    };
  };

  systemd.sleep.settings.Sleep = {
    HibernateDelaySec = "2h";
  };

  hardware.amdgpu.initrd.enable = true;
  programs.corectrl.enable = true;

  users.users.edward.extraGroups = ["corectrl"];

  systemd.services.ryzenadj-battery-limits = {
    description = "Apply Ryzen power limits on battery only";
    wantedBy = ["multi-user.target"];
    after = ["multi-user.target"];

    unitConfig.ConditionACPower = false;

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
}
