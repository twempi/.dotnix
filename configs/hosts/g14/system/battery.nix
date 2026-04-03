{pkgs, ...}: {
  boot.kernelPackages = pkgs.linuxPackages_latest;

  environment.systemPackages = with pkgs; [ryzenadj];

  powerManagement.enable = true;

  services = {
    power-profiles-daemon.enable = true;
    tlp = {
      enable = false;
    };
  };

  hardware.amdgpu.initrd.enable = true;
  programs.corectrl.enable = true;

  users.users.edward.extraGroups = ["corectrl"];
}
