{
  imports = [
    ../../system/configuration.nix
    # ../../system/modules.nix

    ./hardware-configuration.nix
    ./system/g14/asus.nix
    ./system/g14/autogpu.nix
    ./system/g14/battery.nix
    ./system/g14/graphics.nix

    ./system/fish/fish.nix
  ];

  networking = {
    nameservers = ["1.1.1.1" "1.0.0.1" "8.8.8.8"];
    networkmanager.enable = true;
    hostName = "g14";
  };
}
