{pkgs, lib, config, ...}: {
  imports = [

    ./general.nix
    ./keybinds.nix
    # ./env.nix
    ./windowrules.nix
  ];

  stylix.targets.niri.enable = true;
}
