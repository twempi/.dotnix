{
  services.resolved = {
    enable = true;
    settings = {
      Resolve = {
        DNSSEC = false;
        FallbackDNS = ["1.1.1.1" "8.8.8.8"]; 
      };
    };
    # extraConfig = ''
    #   DNSOverTLS=yes
    # '';
  };
}
