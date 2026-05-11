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
  };
in {
  services.tailscale.permitCertUid = "caddy";

  services.caddy = {
    enable = true;
    virtualHosts."t480s.tailae03d0.ts.net".extraConfig = ''
      handle_path /floccus-webdav/* {
        reverse_proxy 127.0.0.1:4918
      }

      handle {
        header Cache-Control "no-store, max-age=0"
        root * ${siteRoot}
        file_server
      }
    '';
  };

  networking.firewall.allowedTCPPorts = [80 443];
}
