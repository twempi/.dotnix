{
  boot.loader.systemd-boot.enable = false;

  fileSystems."/boot/efi" = {
    device = "/dev/disk/by-uuid/B09A-1B30";
    fsType = "vfat";
  };

  boot.loader = {
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/boot/efi";
    };
    grub = {
      enable = true;
      efiSupport = true;
      device = "nodev";
      useOSProber = true;
    };
  };
}
