{pkgs, ...}: {
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

  # Ly converts SIGTERM into exit status 15; supergfxd requires a clean display-manager stop.
  systemd.services.display-manager.serviceConfig.SuccessExitStatus = "15";
  systemd.services.asusd.restartTriggers = [./asusd.ron];
  systemd.services.supergfxd.path = [pkgs.pciutils];
}
