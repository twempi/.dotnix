{config, ...}: let
  inherit (config.flake.modules) nixos;
in {
  flake.modules.nixos.profile-gaming = {
    imports = with nixos; [
      games
      minecraft
    ];
  };
}
