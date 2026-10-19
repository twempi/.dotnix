{
  config,
  inputs,
  ...
}: let
  inherit (config.flake.modules) nixos;
in {
  flake.nixosConfigurations.desktop = inputs.nixpkgs.lib.nixosSystem {
    modules = [nixos.desktop];
  };

  # Host modules are listed in ./system/modules.nix.
  flake.modules.nixos.desktop = {
    imports = with nixos; [
      base
      stylix
      profile-desktop
      profile-gaming

      ./_hardware-configuration.nix
    ];

    networking = {
      nameservers = ["1.1.1.1" "1.0.0.1" "8.8.8.8"];
      networkmanager.enable = true;
      hostName = "desktop";
    };
  };
}
