{
  config,
  inputs,
  ...
}: let
  inherit (config.flake.modules) nixos homeManager;
in {
  flake.nixosConfigurations.t480s = inputs.nixpkgs.lib.nixosSystem {
    modules = [nixos.t480s];
  };

  flake.modules.nixos.t480s = {
    imports = with nixos; [
      base
      stylix
      remote-access

      ./_hardware-configuration.nix

      t480s-battery
      t480s-undervolt
      t480s-graphics
      t480s-minecraft
      t480s-floccus-webdav
      t480s-caddy
      # t480s-pihole
      t480s-suwayomi
      t480s-vaultwarden
      t480s-headless
      t480s-immich
      # t480s-seanime
      t480s-jellyfin
    ];

    home-manager.users.edward.imports = [homeManager.t480s];

    networking.hostName = "t480s";
  };
}
