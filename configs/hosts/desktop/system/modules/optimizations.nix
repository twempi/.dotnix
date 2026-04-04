{ config, pkgs, ... }: {
  # Optimizations
  boot.kernelPackages = pkgs.linuxPackages;
  boot.initrd.kernelModules = [ "ntsync" ];
  boot.kernelParams = [
    "nvidia-drm.modeset=1"
    "mitigations=off"
    "amd_pstate=active"
  ];
  powerManagement.cpuFreqGovernor = "performance";
}
