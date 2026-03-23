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

    supergfxd = {
      enable = true;
      # path = [pkgs.pciutils];
    };
  };
}
