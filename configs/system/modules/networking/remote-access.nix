{
  services.tailscale = {
    enable = true;
  };

  services.openssh = {
    enable = true;
    ports = [22];
    settings = {
      PasswordAuthentication = true;
      AllowUsers = null;
      PermitRootLogin = "prohibit-password";
    };
  };

  networking.firewall.allowedTCPPorts = [22];
}
