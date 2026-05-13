{pkgs, ...}: {
  # Optimizations
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    kernelModules = ["ntsync"];
    kernelParams = [
      "nvidia-drm.modeset=1"
      "nvidia-drm.fbdev=1"
      "mitigations=off"
      "amd_pstate=active"
      "amd_prefcore=enable"
      "amd_dynamic_epp=disable"
    ];
    kernel.sysctl = {
      "vm.swappiness" = 10;
      "vm.vfs_cache_pressure" = 50;
      "vm.max_map_count" = 2147483642;
      "kernel.nmi_watchdog" = 0;
    };
  };

  powerManagement.cpuFreqGovernor = "performance";
  hardware.cpu.amd.updateMicrocode = true;

  services = {
    irqbalance.enable = true;
    scx = {
      enable = true;
      package = pkgs.scx.full;
      scheduler = "scx_lavd";
    };
  };

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 25;
    priority = 100;
  };

  systemd.services.cpu-max-performance = {
    description = "Force maximum CPU performance policy";
    wantedBy = ["multi-user.target"];
    serviceConfig.Type = "oneshot";
    script = ''
      for policy in /sys/devices/system/cpu/cpufreq/policy*; do
        [ -d "$policy" ] || continue

        if [ -w "$policy/scaling_governor" ]; then
          echo performance > "$policy/scaling_governor"
        fi

        if [ -w "$policy/energy_performance_preference" ]; then
          echo performance > "$policy/energy_performance_preference"
        fi
      done

      if [ -w /sys/devices/system/cpu/cpufreq/boost ]; then
        echo 1 > /sys/devices/system/cpu/cpufreq/boost
      fi
    '';
  };
}
