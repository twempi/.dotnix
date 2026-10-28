{
  flake.modules.nixos.t480s-media-downloads = {
    config,
    lib,
    pkgs,
    ...
  }: let
    downloadsDir = "/srv/downloads";
    vpnTable = "51820";
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

    sops.secrets.proton_wg_private_key = {
      sopsFile = ../../../../../secrets/proton.yaml;
      restartUnits = ["wireguard-proton0.service"];
    };

    # Proton VPN (US-CA#233). Its routes go in a separate table, not main, so SSH, Caddy,
    # and Tailscale keep the normal uplink; only qBittorrent's traffic is sent here.
    networking.wireguard.interfaces.proton0 = {
      ips = ["10.2.0.2/32" "2a07:b944::2:2/128"];
      privateKeyFile = config.sops.secrets.proton_wg_private_key.path;
      table = vpnTable;
      peers = [
        {
          publicKey = "Nm/K6UQLBTliioKl4b/1bXeyvGCXyhm1DW6Ja9cTNkw=";
          endpoint = "146.70.174.210:51820";
          allowedIPs = ["0.0.0.0/0" "::/0"];
          persistentKeepalive = 25;
        }
      ];
    };

    # Kill switch: rule 6000 sends qBittorrent's traffic to the tunnel's table. While the tunnel is
    # down that table is empty, so the lookup falls through to rule 6001, which rejects the traffic
    # instead of letting it reach the main table. Both sit after Tailscale's rules (5210-5270), so
    # WebUI replies to tailnet clients still go out tailscale0.
    # These rules are owned here, not by wireguard-proton0, so they stay in place when the tunnel stops.
    systemd.services.qbittorrent-vpn-routing = let
      # Only adds missing rules, so reapplying never leaves a moment without them.
      addRules = ''
        uid=$(id -u ${config.services.qbittorrent.user})
        for family in -4 -6; do
          ip "$family" rule show priority 6000 | grep -q "uidrange $uid-$uid lookup ${vpnTable}" ||
            ip "$family" rule add uidrange "$uid-$uid" lookup ${vpnTable} priority 6000
          ip "$family" rule show priority 6001 | grep -q "uidrange $uid-$uid unreachable" ||
            ip "$family" rule add uidrange "$uid-$uid" unreachable priority 6001
        done
      '';
    in {
      description = "Route qBittorrent traffic through Proton VPN";
      wantedBy = ["multi-user.target"];
      before = ["qbittorrent.service"];
      requiredBy = ["qbittorrent.service"];
      path = [pkgs.iproute2];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = addRules;
      # Rebuilds reload this unit in place. A restart would also restart qBittorrent through
      # requiredBy, and the qbittorrent module lets its shutdown take up to 30 minutes.
      reloadIfChanged = true;
      reload = addRules;
      postStop = ''
        uid=$(id -u ${config.services.qbittorrent.user})
        for family in -4 -6; do
          ip "$family" rule del uidrange "$uid-$uid" lookup ${vpnTable} priority 6000 2>/dev/null || true
          ip "$family" rule del uidrange "$uid-$uid" unreachable priority 6001 2>/dev/null || true
        done
      '';
    };
  };
}
