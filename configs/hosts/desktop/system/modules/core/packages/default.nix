{inputs, ...}: {
  flake.modules.nixos.desktop-packages = {pkgs, ...}: let
    system = pkgs.stdenv.hostPlatform.system;
  in {
    environment.systemPackages = [
      inputs.home-manager.packages.${system}.default
      pkgs.nvfancontrol
    ];
  };
}
