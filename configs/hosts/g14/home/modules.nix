{
  config,
  inputs,
  withSystem,
  ...
}: let
  inherit (config.flake.modules) homeManager;
in {
  flake.homeConfigurations.edward-g14 = withSystem "x86_64-linux" ({pkgs, ...}:
    inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [
        homeManager.g14
        homeManager.stylix
      ];
    });

  flake.modules.homeManager.g14 = {
    imports = with homeManager; [
      profile-desktop
      g14-hyprland
      g14-sway
      g14-refresh-rate
      g14-clamshell
      g14-noctalia-gpu
      g14-fastfetch
    ];

    _module.args.hostname = "g14";
  };
}
