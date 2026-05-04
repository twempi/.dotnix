{pkgs, ...}: let
  siteRoot = pkgs.lib.cleanSource ./startpage;
in {
  services.tailscale.permitCertUid = "caddy";

  services.caddy = {
    enable = true;
    virtualHosts."t480s.tailae03d0.ts.net".extraConfig = ''
      handle_path /floccus-webdav/* {
        reverse_proxy 127.0.0.1:4918
      }

      handle {
        root * ${siteRoot}
        file_server
      }
    '';
  };

  networking.firewall.allowedTCPPorts = [80 443];
}
