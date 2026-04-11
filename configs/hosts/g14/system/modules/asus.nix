{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    asusctl
    supergfxctl
  ];

  services = {
    asusd = {
      enable = true;
      asusdConfig.text = ''
        {
          "bat_charge_limit": 90
        }
      '';
    };

    supergfxd.enable = true;
  };

  systemd.services.supergfxd.path = [ pkgs.pciutils ];
}
