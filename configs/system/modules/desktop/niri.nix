{
  inputs,
  pkgs,
  ...
}: let
  system = pkgs.stdenv.hostPlatform.system;
  niriPackage = inputs.niri.packages.${system}.niri-unstable;
in {
  imports = [
    inputs.niri.nixosModules.niri
  ];

  programs.niri = {
    enable = true;
    package = niriPackage;
  };

  niri-flake.cache.enable = true;

  xdg.portal.config.niri.default = ["gnome" "gtk"];
}
