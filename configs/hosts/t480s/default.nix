{
  imports = [
    ../../system/base.nix
    ../../system/modules/theme/stylix.nix
    ../../system/modules/networking/remote-access.nix
    ../../system/modules/core/bootloader.nix
    ../../system/modules/core/user.nix
    ../../system/modules/core/shell.nix
    ../../system/modules/core/nh.nix
    ../../system/modules/core/home-manager.nix
    ../../system/modules/core/cachix.nix

    ./hardware-configuration.nix

    ./system/modules.nix
  ];

  networking = {
    nameservers = ["1.1.1.1" "1.0.0.1" "8.8.8.8"];
    networkmanager.enable = true;
    hostName = "t480s";
  };
}
