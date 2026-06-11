{
  config,
  pkgs,
  ...
}: let
  mkStylixStartpage = import ./startpage/lib/mkStylixStartpage.nix;
  siteRoot = mkStylixStartpage {
    inherit pkgs;
    source = ./startpage;
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

      handle /settings.json {
        header Cache-Control "no-store, max-age=0"
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

  systemd.tmpfiles.rules = [
    "d /var/lib/startpage 0750 edward caddy -"
    "C /var/lib/startpage/settings.json 0640 edward caddy - ${./startpage/settings.default.json}"
  ];

  networking.firewall.allowedTCPPorts = [80 443];
}
