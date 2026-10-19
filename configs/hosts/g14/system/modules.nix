{config, ...}: let
  inherit (config.flake.modules) nixos;
in {
  flake.modules.nixos.g14 = {lib, ...}: {
    imports = with nixos; [
      g14-asus
      g14-battery
      g14-graphics
      g14-display-sessions
    ];

    # `edward-g14` is activated through the standalone Home Manager output.
    # Do not let the NixOS generation overwrite its home files.
    home-manager.users = lib.mkForce {};
  };
}
