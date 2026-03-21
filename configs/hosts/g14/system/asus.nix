{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    asusctl
    supergfxctl
  ];

  services = {
    asusd = {
      enable = true;
      enableUserService = true;
    };

    supergfxd.path = [pkgs.pciutils];
  };
}
