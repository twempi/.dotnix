{
  imports = [
    ../../system/base.nix
    ../../system/profiles/theming.nix
    ../../system/profiles/desktop.nix
    ../../system/profiles/gaming.nix

    ./hardware-configuration.nix

    ./system/modules.nix
  ];

  networking = {
    nameservers = ["1.1.1.1" "1.0.0.1" "8.8.8.8"];
    networkmanager.enable = true;
    hostName = "desktop";
  };
}
