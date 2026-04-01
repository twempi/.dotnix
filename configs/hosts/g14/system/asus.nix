{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    asusctl
    supergfxctl
    libnotify
  ];

  services = {
    asusd.enable = true;
    supergfxd.enable = true;
  };

  systemd.services.supergfxd.path = [pkgs.pciutils];

  environment.etc."asusd/asusd.conf".text = ''
    {
      "bat_charge_limit": 85
    }
  '';
}
