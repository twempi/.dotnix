{
  flake.modules.nixos.t480s-media-downloads = {lib, ...}: let
    downloadsDir = "/srv/downloads";
  in {
    services.sonarr.enable = true;

    services.prowlarr.enable = true;

    services.qbittorrent = {
      enable = true;
      # 8080 is Suwayomi's.
      webuiPort = 8081;
      torrentingPort = 50000;
      extraArgs = ["--confirm-legal-notice"];
    };

    users.users.sonarr.extraGroups = ["media"];
    users.users.qbittorrent.extraGroups = ["media"];

    # Group-writable output so edward, Sonarr, and qBittorrent can move and delete each other's files.
    systemd.services.sonarr.serviceConfig.UMask = lib.mkForce "0002";
    systemd.services.qbittorrent.serviceConfig.UMask = "0002";

    systemd.tmpfiles.rules = [
      "d ${downloadsDir} 2770 qbittorrent media - -"
    ];

    # Admin UIs stay off the LAN. The peer port stays closed until a VPN with port forwarding exists.
    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [8989 9696 8081];
  };
}
