{
  imports = [
    ../../system/configuration.nix

    ./hardware-configuration.nix

    ./system/battery.nix
    ./system/undervolt.nix
    ./system/graphics.nix

    ./home/fish/fish.nix

    ./minecraft
  ];

  networking = {
    nameservers = ["1.1.1.1" "1.0.0.1" "8.8.8.8"];
    networkmanager.enable = true;
    hostName = "t480s";
  };
}
