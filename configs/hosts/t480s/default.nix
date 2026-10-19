{
  config,
  inputs,
  ...
}: let
  inherit (config.flake.modules) nixos homeManager;
in {
  flake.nixosConfigurations.t480s = inputs.nixpkgs.lib.nixosSystem {
    modules = [nixos.t480s];
  };

  # Host modules are listed in ./system/modules.nix.
  flake.modules.nixos.t480s = {
    imports = with nixos; [
      base
      stylix
      remote-access
      bootloader
      user
      shell
      nh
      home-manager
      cachix

      ./_hardware-configuration.nix
    ];

    home-manager.users.edward.imports = [homeManager.t480s];

    networking = {
      nameservers = ["1.1.1.1" "1.0.0.1" "8.8.8.8"];
      networkmanager.enable = true;
      hostName = "t480s";
    };
  };
}
