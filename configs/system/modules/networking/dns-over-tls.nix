{
  services.resolved = {
    enable = false;
    settings = {
      Resolve = {
        DNSSEC = false;
        DNS = ["1.1.1.1" "1.0.0.1" "8.8.8.8"];
        DNSOverTLS = true;
      };
    };
  };
}
