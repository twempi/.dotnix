{inputs, ...}: {
  imports = [
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-t480s
  ];

  powerManagement = {
    enable = true;
    powertop.enable = false;
  };
  services = {
    thermald.enable = true;

    tlp = {
      enable = true;
      settings = {
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
        CPU_BOOST_ON_AC = 1;

        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
        CPU_ENERGY_PERF_POLICY_ON_BAT = "default";
        CPU_BOOST_ON_BAT = 1;

        CPU_SCALING_GOVERNOR_ON_SAV = "powersave";
        CPU_ENERGY_PERF_POLICY_ON_SAV = "balance_performance";

        CPU_MAX_PERF_ON_BAT = 80;
        CPU_MIN_PERF_ON_BAT = 0;

        STOP_CHARGE_THRESH_BAT0 = 95;
        START_CHARGE_THRESH_BAT0 = 80;
      };
    };

    power-profiles-daemon.enable = false;
    logind = {
      settings = {
        Login = {
          HandleLidSwitch = "suspend-then-hibernate";
          HandlePowerKeyLongPress = "hibernate";
          HandlePowerKey = "poweroff";
        };
      };
    };
  };
  boot.kernelParams = ["mem_sleep_default=deep"];

  systemd.sleep.settings.Sleep = {
    AllowSuspend = true;
    AllowHibernation = true;
    AllowHybridSleep = true;
    AllowSuspendThenHibernate = true;
  };
}
