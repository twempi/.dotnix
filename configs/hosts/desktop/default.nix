{
  imports = [
    ../../system/base.nix
    ../../system/modules/theme/stylix.nix
    ../../system/profiles/desktop.nix
    ../../system/profiles/gaming.nix

    ./hardware-configuration.nix

    ./system/modules.nix
  ];

  # USB serial devices used for Arduino uploads are owned by this group.
  users.users.edward.extraGroups = ["dialout"];

  networking = {
    nameservers = ["1.1.1.1" "1.0.0.1" "8.8.8.8"];
    networkmanager.enable = true;
    hostName = "desktop";
  };
}
