{
  imports = [
    ../../system/configuration.nix
    # ../../system/modules.nix

    ./hardware-configuration.nix

    ./system/asus.nix
    ./system/autogpu.nix
    ./system/battery.nix
    ./system/graphics.nix

    ./home/fish/fish.nix
  ];

  networking = {
    nameservers = ["1.1.1.1" "1.0.0.1" "8.8.8.8"];
    networkmanager.enable = true;
    hostName = "g14";
  };
}
