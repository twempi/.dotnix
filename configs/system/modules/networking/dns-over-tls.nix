{
  flake.modules.nixos.dns-over-tls = {
    services.resolved = {
      enable = true;
      settings = {
        Resolve = {
          DNSSEC = false;
          DNS = ["1.1.1.1" "1.0.0.1" "8.8.8.8"];
          DNSOverTLS = true;
        };
      };
    };
  };
}
