{
  config,
  inputs,
  ...
}: let
  inherit (config.flake.modules) nixos;
in {
  flake.nixosConfigurations.g14 = inputs.nixpkgs.lib.nixosSystem {
    modules = [nixos.g14];
  };

  # Host modules are listed in ./system/modules.nix.
  flake.modules.nixos.g14 = {
    imports = with nixos; [
      inputs.nixos-hardware.nixosModules.asus-zephyrus-ga402

      base
      stylix
      profile-desktop
      profile-gaming

      ./_hardware-configuration.nix
    ];

    networking = {
      nameservers = ["1.1.1.1" "1.0.0.1" "8.8.8.8"];
      networkmanager.enable = true;
      networkmanager.wifi.powersave = true;
      hostName = "g14";
    };
  };
}
