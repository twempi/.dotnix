{
  config,
  inputs,
  withSystem,
  ...
}: let
  inherit (config.flake.modules) homeManager;
in {
  flake.homeConfigurations.edward-desktop = withSystem "x86_64-linux" ({pkgs, ...}:
    inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [
        homeManager.desktop
        homeManager.stylix
        # niri-flake's NixOS module adds these to NixOS-managed Home Manager users on its own.
        inputs.niri.homeModules.config
        inputs.niri.homeModules.stylix
      ];
    });

  flake.modules.homeManager.desktop = {
    imports = with homeManager; [
      profile-desktop
      desktop-hyprland
      desktop-sway
      desktop-niri
      desktop-fish
      desktop-graphics-tools
    ];

    _module.args.hostname = "desktop";
  };
}
