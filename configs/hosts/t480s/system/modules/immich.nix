{
  flake.modules.nixos.t480s-immich = {pkgs, ...}: let
    immichMediaDir = "/srv/immich";
    immichPort = 2283;
  in {
    services.immich = {
      enable = true;

      host = "127.0.0.1";
      port = immichPort;
      openFirewall = false;

      mediaLocation = immichMediaDir;
      machine-learning.enable = true;
      accelerationDevices = ["/dev/dri/renderD128"];
    };

    systemd.services.tailscale-serve-immich = import ./_tailscale-serve-service.nix {
      inherit pkgs;
      name = "immich";
      description = "Expose Immich as a Tailscale Service";
      port = immichPort;
    };

    users.users.immich.extraGroups = ["video" "render"];

    systemd.tmpfiles.rules = [
      "d ${immichMediaDir} 0700 immich immich - -"
    ];
  };
}
