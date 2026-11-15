{
  flake.modules.nixos.desktop-boot = {
    # Boot settings
    boot = {
      loader = {
        grub = {
        };
      };
    };
    boot.supportedFilesystems = ["ntfs"];
  };
}
