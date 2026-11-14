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
      # desktop-open-webui
      # desktop-comfyui
    ];

    networking.hostName = "desktop";

    home-manager.users = lib.mkForce {};
  };
}
