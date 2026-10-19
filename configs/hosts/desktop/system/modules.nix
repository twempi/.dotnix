{config, ...}: let
  inherit (config.flake.modules) nixos;
in {
  flake.modules.nixos.desktop = {lib, ...}: {
    imports = with nixos; [
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

    # `edward-desktop` is activated through the standalone Home Manager output.
    # Do not let the NixOS generation overwrite its home files during boot.
    home-manager.users = lib.mkForce {};
  };
}
