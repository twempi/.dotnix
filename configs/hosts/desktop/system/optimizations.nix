{ config, pkgs, ... }: {
  # Optimizations
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.initrd.kernelModules = [ "ntsync" ];
  boot.kernelParams = [
    "mitigations=off"     
    "amd_pstate=active"   
  ];
  powerManagement.cpuFreqGovernor = "performance";
}
