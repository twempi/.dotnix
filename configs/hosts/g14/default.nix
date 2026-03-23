{
  imports = [
    ../../system/configuration.nix
    # ../../system/modules.nix

    ./hardware-configuration.nix
    ./system/asus.nix
    ./system/graphics.nix

    ./programs/fish
  ];

  networking = {
    nameservers = ["1.1.1.1" "1.0.0.1" "8.8.8.8"];
    networkmanager.enable = true;
    hostName = "g14";
  };
}
