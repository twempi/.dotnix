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

  flake.modules.nixos.g14 = {lib, ...}: {
    imports = with nixos; [
      inputs.nixos-hardware.nixosModules.asus-zephyrus-ga402

      base
      stylix
      profile-desktop
      profile-gaming

      ./_hardware-configuration.nix

      g14-asus
      g14-battery
      g14-graphics
      g14-display-sessions
    ];

    networking = {
      networkmanager.wifi.powersave = true;
      hostName = "g14";
    };

    # `edward-g14` is activated through the standalone Home Manager output.
    # Do not let the NixOS generation overwrite its home files.
    home-manager.users = lib.mkForce {};
  };
}
