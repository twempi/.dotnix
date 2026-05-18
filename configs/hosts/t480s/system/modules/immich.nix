{pkgs, ...}: let
  immichMediaDir = "/srv/immich";

  immichInternalPort = 2283;
  immichExternalPort = 2283;
in {
  services.immich = {
    enable = true;

    host = "127.0.0.1";
    port = immichInternalPort;
    openFirewall = false;

    mediaLocation = immichMediaDir;
    machine-learning.enable = true;
    accelerationDevices = ["/dev/dri/renderD128"];
  };

  services.tailscale.serve.services.immich = {
    endpoints = {
      "tcp:${toString immichExternalPort}" = "http://127.0.0.1:${toString immichInternalPort}";
    };

    advertised = true;
  };

  users.users.immich.extraGroups = ["video" "render"];

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
    ];
  };

  systemd.tmpfiles.rules = [
    "d ${immichMediaDir} 0700 immich immich - -"
  ];
}
