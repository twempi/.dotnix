{
  config,
  inputs,
  pkgs,
  ...
}: let
  startpageSource = inputs.twempi.inputs.startpage-src;
  mkStylixStartpage = import "${startpageSource}/lib/mkStylixStartpage.nix";
  siteRoot = mkStylixStartpage {
    inherit pkgs;
    source = startpageSource;
    colors = config.lib.stylix.colors;
    fontFamily = config.stylix.fonts.monospace.name;
    sansFontFamily = config.stylix.fonts.sansSerif.name;
  };
in {
  services.tailscale.permitCertUid = "caddy";

  services.caddy = {
    enable = true;
    virtualHosts."t480s.tailae03d0.ts.net".extraConfig = ''
      handle_path /floccus-webdav/* {
        reverse_proxy 127.0.0.1:4918
      }

      handle /api/settings {
        reverse_proxy 127.0.0.1:4919
      }

      handle /settings.json {
        header Cache-Control "no-store, max-age=0"
        header Access-Control-Allow-Origin "*"
        root * /var/lib/startpage
        file_server
      }

      handle {
        header Cache-Control "no-store, max-age=0"
        root * ${siteRoot}
        file_server
      }
    '';
  };

  systemd.services.startpage-settings-api = {
    description = "Startpage central settings API";
    after = ["network.target"];
    wantedBy = ["multi-user.target"];
    environment = {
      STARTPAGE_SETTINGS_FILE = "/var/lib/startpage/settings.json";
      STARTPAGE_SETTINGS_HOST = "127.0.0.1";
      STARTPAGE_SETTINGS_PORT = "4919";
      STARTPAGE_SETTINGS_ORIGIN = "https://t480s.tailae03d0.ts.net";
    };
    serviceConfig = {
      Type = "simple";
      User = "startpage";
      Group = "caddy";
      ExecStart = "${pkgs.python3}/bin/python ${startpageSource}/settings-api.py";
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ReadWritePaths = ["/var/lib/startpage"];
      ProtectHome = true;
      Restart = "on-failure";
    };
  };

  users.users.startpage = {
    isSystemUser = true;
    group = "caddy";
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/startpage 0750 startpage caddy -"
    "C /var/lib/startpage/settings.json 0640 startpage caddy - ${startpageSource}/settings.default.json"
    # Hand existing settings over from the old edward-owned file.
    "z /var/lib/startpage/settings.json 0640 startpage caddy -"
  ];

  # Only reachable over Tailscale; not exposed on LAN/Wi-Fi.
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [80 443];
}
