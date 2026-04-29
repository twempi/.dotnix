{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    asusctl
    supergfxctl
  ];

  services = {
    asusd = {
      enable = true;
      asusdConfig.source = ./asusd.ron;
    };

    supergfxd.enable = true;
  };

  systemd.services.supergfxd.path = [ pkgs.pciutils ];
}
