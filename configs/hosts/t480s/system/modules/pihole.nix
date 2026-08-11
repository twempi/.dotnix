{pkgs, ...}: let
  webPort = 8081;
in {
  services.pihole-ftl = {
    enable = true;

    openFirewallDNS = false;
    openFirewallDHCP = false;
    openFirewallWebserver = false;

    privacyLevel = 0;

    lists = [
      {
        url = "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts";
        description = "StevenBlack unified hosts list";
      }
    ];

    queryLogDeleter = {
      enable = true;
      age = 30;
      interval = "weekly";
    };

    settings = {
      dns = {
        upstreams = ["1.1.1.1" "1.0.0.1"];
        interface = "enp0s31f6";
        listeningMode = "SINGLE";
      };

      dhcp.active = false;
      misc.readOnly = true;
      webserver.api = {
        cli_pw = true;
        pwhash = "";
      };
    };
  };

  services.pihole-web = {
    enable = true;
    hostName = "pihole.tailae03d0.ts.net";
    ports = ["127.0.0.1:${toString webPort}"];
  };

  networking.firewall.interfaces.enp0s31f6 = {
    allowedTCPPorts = [53];
    allowedUDPPorts = [53];
  };

  systemd.services.tailscale-serve-pihole = {
    description = "Expose Pi-hole as a Tailscale Service";
    after = [
      "pihole-ftl.service"
      "tailscaled.service"
    ];
    wants = [
      "pihole-ftl.service"
      "tailscaled.service"
    ];
    wantedBy = ["multi-user.target"];

    restartIfChanged = true;

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      TimeoutStartSec = 30;
      ExecStop = "${pkgs.util-linux}/bin/flock -w 120 /run/tailscale-serve.lock ${pkgs.tailscale}/bin/tailscale serve clear svc:pihole";
    };

    script = ''
      set -euo pipefail

      ${pkgs.util-linux}/bin/flock -w 120 /run/tailscale-serve.lock \
        ${pkgs.tailscale}/bin/tailscale serve --yes --bg \
          --service=svc:pihole \
          --https=${toString webPort} \
          http://127.0.0.1:${toString webPort}
    '';
  };
}
