{
  config,
  inputs,
  lib,
  withSystem,
  ...
}: let
  inherit (config.flake.modules) homeManager;
in {
  flake.homeConfigurations.edward-t480s = withSystem "x86_64-linux" ({pkgs, ...}:
    inputs.home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = [
        homeManager.t480s
        homeManager.stylix
      ];
    });

  # Also imported by the NixOS-managed Home Manager user in ../default.nix.
  flake.modules.homeManager.t480s = {
    imports = with homeManager; [
      profile-server
      t480s-fastfetch
      t480s-hermes-agent
    ];

    _module.args.hostname = "t480s";

    # base16-fish recolors the terminal palette on shell start, which leaks into the SSH client's terminal.
    stylix.targets.fish.enable = lib.mkForce false;
  };
}
