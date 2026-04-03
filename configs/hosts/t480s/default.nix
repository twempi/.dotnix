{
  imports = [
    ../../system/configuration.nix

    ./hardware-configuration.nix

    ./system/battery.nix
    ./system/undervolt.nix
<<<<<<< Updated upstream
    ./system/graphics.nix
=======
    # ./system/playit.nix
>>>>>>> Stashed changes

    ./home/fish/fish.nix

    ./system/minecraft.nix
  ];

  networking = {
    nameservers = ["1.1.1.1" "1.0.0.1" "8.8.8.8"];
    networkmanager.enable = true;
    hostName = "t480s";
  };
}
