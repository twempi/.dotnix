{lib, ...}: {
  imports = [
    ./modules/asus.nix
    ./modules/battery.nix
    ./modules/graphics.nix
    ./modules/display-sessions.nix
  ];

  # `edward-g14` is activated through the standalone Home Manager output.
  # Do not let the NixOS generation overwrite its home files.
  home-manager.users = lib.mkForce {};
}
