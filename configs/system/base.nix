{
  config,
  inputs,
  ...
}: let
  inherit (config.flake.modules) nixos;
in {
  flake.modules.nixos.base = {
    imports = with nixos; [
      inputs.sops-nix.nixosModules.sops

      bootloader
      user
      shell
      nh
      home-manager
      cachix
    ];

    i18n.defaultLocale = "en_US.UTF-8";

    time.timeZone = "America/Los_Angeles";

    nix.settings.experimental-features = ["nix-command" "flakes"];

    nixpkgs.config.allowUnfree = true;

    system.stateVersion = "25.05";

    hardware.enableRedistributableFirmware = true;

    networking = {
      nameservers = ["1.1.1.1" "1.0.0.1" "8.8.8.8"];
      networkmanager.enable = true;
    };
  };
}
