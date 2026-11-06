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
      ];
    });

  flake.modules.homeManager.desktop = {
    imports = with homeManager; [
      profile-desktop
      desktop-hyprland
      desktop-sway
      desktop-graphics-tools
      desktop-sioyek
    ];

    _module.args.hostname = "desktop";
  };
}
