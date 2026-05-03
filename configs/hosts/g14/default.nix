{
  imports = [
    ../../system/base.nix
    ../../system/profiles/desktop.nix
    ../../system/profiles/gaming.nix
    ../../system/profiles/laptop.nix

    ./hardware-configuration.nix

    ./system/modules.nix
  ];

  networking = {
    nameservers = ["1.1.1.1" "1.0.0.1" "8.8.8.8"];
    networkmanager.enable = true;
    hostName = "g14";
  };
}
