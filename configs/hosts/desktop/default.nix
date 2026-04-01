{
  imports = [
    ../../system/configuration.nix

    ./hardware-configuration.nix

    ./system/desktop/boot.nix
    ./system/desktop/drives.nix
    ./system/desktop/graphics.nix
    ./system/desktop/optimizations.nix
    ./system/desktop/polkit.nix
    ./system/desktop/services.nix
    ./system/desktop/aoc-q27g3xmn.nix
    ./system/desktop/packages.nix


    ./minecraft

    ./system/fish/fish.nix
  ];

  networking = {
    nameservers = ["1.1.1.1" "1.0.0.1" "8.8.8.8"];
    networkmanager.enable = true;
    hostName = "desktop";
  };
}
