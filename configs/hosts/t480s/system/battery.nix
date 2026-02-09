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
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
        CPU_SCALING_GOVERNOR_ON_SAV = "powersave";

        CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
        CPU_ENERGY_PERF_POLICY_ON_BAT = "default";
        CPU_ENERGY_PERF_POLICY_ON_SAV = "power";

        CPU_BOOST_ON_AC = 1;
        CPU_BOOST_ON_BAT = 1;
        STOP_CHARGE_THRESH_BAT0 = 95;
        START_CHARGE_THRESH_BAT0 = 0;
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

  systemd.sleep.extraConfig = ''
    HibernateDelaySec=30m
    SuspendState=mem
  '';
}
