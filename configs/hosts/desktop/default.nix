{
  imports = [
    ../../system/configuration.nix

    ./hardware-configuration.nix

    ./system/boot.nix
    ./system/drives.nix
    ./system/graphics.nix
    ./system/optimizations.nix
    ./system/polkit.nix
    ./system/services.nix
    ./system/aoc-q27g3xmn.nix
    ./system/packages.nix

    ./home/fish/fish.nix
  ];

  networking = {
    nameservers = ["1.1.1.1" "1.0.0.1" "8.8.8.8"];
    networkmanager.enable = true;
    hostName = "desktop";
  };
}
