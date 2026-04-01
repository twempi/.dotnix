{
  imports = [
    ../../system/configuration.nix

    ./hardware-configuration.nix

    ./system/t480s/battery.nix
    ./system/t480s/undervolt.nix
    ./system/t480s/graphics.nix

    ./system/fish/fish.nix

    ./minecraft
  ];

  networking = {
    nameservers = ["1.1.1.1" "1.0.0.1" "8.8.8.8"];
    networkmanager.enable = true;
    hostName = "t480s";
  };
}
