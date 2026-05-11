{pkgs, ...}: {
  # Optimizations
  boot.kernelPackages = pkgs.linuxPackages;
  # boot.initrd.kernelModules = ["ntsync"];
  boot.kernelParams = [
    "nvidia-drm.modeset=1"
    # "mitigations=off"
    "amd_pstate=disable"
  ];
  # powerManagement.cpuFreqGovernor = "performance";
  powerManagement.cpuFreqGovernor = "schedutil";
  hardware.cpu.amd.updateMicrocode = true;
}
