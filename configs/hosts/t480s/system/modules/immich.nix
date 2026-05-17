{ pkgs, ... }:

let
  immichMediaDir = "/srv/immich";
in {
  services.immich = {
    enable = true;

    host = "127.0.0.1";
    port = 2283;
    openFirewall = false;

    mediaLocation = immichMediaDir;
    machine-learning.enable = true;
    accelerationDevices = [ "/dev/dri/renderD128" ];
  };

  users.users.immich.extraGroups = [ "video" "render" ];

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
