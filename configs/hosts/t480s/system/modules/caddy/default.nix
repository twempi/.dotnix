{pkgs, ...}: let
  siteRoot = pkgs.lib.cleanSource ./startpage;
in {
  services.tailscale = {
    enable = true;
    permitCertUid = "caddy";
  };

  services.caddy = {
    enable = true;
    virtualHosts."t480s.your-tailnet.ts.net".extraConfig = ''
      root * ${siteRoot}
      file_server
    '';
  };

  networking.firewall.allowedTCPPorts = [80 443];
}
