{pkgs, ...}: let
  siteRoot = pkgs.lib.cleanSource ./startpage;
in {
  services.tailscale.permitCertUid = "caddy";

  services.caddy = {
    enable = true;
    virtualHosts."t480s.tailae03d0.ts.net".extraConfig = ''
      root * ${siteRoot}
      file_server
    '';
  };

  networking.firewall.allowedTCPPorts = [80 443];
}
