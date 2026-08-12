{ ... }: {
  services.pihole-ftl = {
    enable = true;

    lists = [
      {
        url = "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts";
      }
    ];

    settings.dns = {
      upstreams = [
        "1.1.1.1"
        "1.0.0.1"
      ];

      interface = "enp0s31f6";
      listeningMode = "SINGLE";
    };
  };

  services.pihole-web = {
    enable = true;
    ports = [ "127.0.0.1:8081" ];
  };

  networking.firewall.interfaces.enp0s31f6 = {
    allowedTCPPorts = [ 53 ];
    allowedUDPPorts = [ 53 ];
  };
}
