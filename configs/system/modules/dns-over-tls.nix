{
  services.resolved = {
    enable = true;
    dnssec = "false";
    fallbackDns = ["1.1.1.1" "8.8.8.8"];
    extraConfig = ''
      DNSOverTLS=yes
    '';
  };
}
