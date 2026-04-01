{ pkgs, ... }:
{
  boot.kernelPackages = pkgs.linuxPackages_latest;

  powerManagement.enable = true;

  services = {
    power-profiles-daemon.enable = true;
    tlp.enable = false;
  };

  hardware.amdgpu.initrd.enable = true;
}
