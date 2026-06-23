{pkgs, ...}: let
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

  systemd.services.tailscale-serve-immich = {
    description = "Expose Immich as a Tailscale Service";
    after = ["tailscaled.service"];
    wants = ["tailscaled.service"];
    wantedBy = ["multi-user.target"];

    restartIfChanged = true;

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      TimeoutStartSec = 30;
    };

    script = ''
      set -euo pipefail

      ${pkgs.util-linux}/bin/flock -w 120 /run/tailscale-serve.lock \
        ${pkgs.tailscale}/bin/tailscale serve --yes --bg \
          --service=svc:immich \
          --https=${toString immichPort} \
          http://127.0.0.1:${toString immichPort}
    '';
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
