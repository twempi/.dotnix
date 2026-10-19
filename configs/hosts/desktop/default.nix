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

  flake.modules.nixos.desktop = {lib, ...}: {
    imports = with nixos; [
      base
      stylix
      profile-desktop
      profile-gaming

      ./_hardware-configuration.nix

      desktop-aoc-q27g3xmn
      desktop-boot
      desktop-drives
      desktop-graphics
      desktop-optimizations
      desktop-packages
      desktop-polkit
      desktop-openrgb
      desktop-gesturelight
      # desktop-ollama
      # desktop-comfyui-flux
    ];

    networking.hostName = "desktop";

    # `edward-desktop` is activated through the standalone Home Manager output.
    # Do not let the NixOS generation overwrite its home files during boot.
    home-manager.users = lib.mkForce {};
  };
}
