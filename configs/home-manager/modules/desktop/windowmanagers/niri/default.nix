{pkgs, ...}: {
  imports = [
    ../../amane
    ./general.nix
    ./keybinds.nix
    ./windowrules.nix
  ];

  programs.niri.package = pkgs.niri;
  stylix.targets.niri.enable = true;
}
