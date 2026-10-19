{config, ...}: let
  inherit (config.flake.modules) nixos;
in {
  flake.modules.nixos.t480s = {
    imports = with nixos; [
      t480s-battery
      t480s-undervolt
      t480s-graphics
      t480s-minecraft
      t480s-floccus-webdav
      t480s-caddy
      t480s-pihole
      t480s-suwayomi
      t480s-vaultwarden
      t480s-headless
      t480s-immich
      # t480s-seanime
      # t480s-jellyfin
    ];
  };
}
