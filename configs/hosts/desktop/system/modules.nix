{lib, ...}: {
  imports = [
    ./modules/aoc-q27g3xmn.nix
    ./modules/boot.nix
    ./modules/drives.nix
    ./modules/graphics.nix
    ./modules/optimizations.nix
    ./modules/packages.nix
    ./modules/polkit.nix
    ./modules/services.nix
  ];

  # `edward-desktop` is activated through the standalone Home Manager output.
  # Do not let the NixOS generation overwrite its home files during boot.
  home-manager.users = lib.mkForce {};
}
