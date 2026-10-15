{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    ./general.nix
    ./keybinds.nix
    ./windowrules.nix
  ];

  programs.niri.package = inputs.niri.packages.${pkgs.stdenv.hostPlatform.system}.niri-unstable;
  stylix.targets.niri.enable = true;
}
