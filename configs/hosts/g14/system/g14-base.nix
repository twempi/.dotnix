{pkgs, ...}: {
  boot.kernelPackages = pkgs.linuxPackages_latest;

  powerManagement.enable = true;

  environment.systemPackages = with pkgs; [
    asusctl
    supergfxctl
    tlp
    lact
  ];

  services = {
    asusd = {
      enable = true;
      enableUserService = true;
    };
    supergfxd.enable = true;

    tlp = {
      enable = true;
      settings = {
        # CPU
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

        CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
        CPU_ENERGY_PERF_POLICY_ON_BAT = "power";

        CPU_BOOST_ON_AC = 1;
        CPU_BOOST_ON_BAT = 0;

        # ASUS platform profile
        # PLATFORM_PROFILE_ON_AC = "performance";
        # PLATFORM_PROFILE_ON_BAT = "low-power";
        #
        # # AMD graphics power behavior
        # RADEON_DPM_PERF_LEVEL_ON_AC = "auto";
        # RADEON_DPM_PERF_LEVEL_ON_BAT = "auto";
        #
        # RADEON_DPM_STATE_ON_AC = "performance";
        # RADEON_DPM_STATE_ON_BAT = "battery";
        #
        # AMDGPU_ABM_LEVEL_ON_AC = 0;
        # AMDGPU_ABM_LEVEL_ON_BAT = 3;
      };
    };

    lact.enable = true;
  };

  systemd.services.supergfxd.path = [pkgs.pciutils];

  hardware.amdgpu = {
    initrd.enable = true;

    overdrive = {
      enable = true;
      ppfeaturemask = "0xfffd7fff";
    };
  };

  environment.etc."asusd/asusd.conf".text = ''
    {
      "bat_charge_limit": 95
    }
  '';
}
