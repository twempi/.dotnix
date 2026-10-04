{pkgs, ...}: {
  environment.systemPackages = [
    pkgs.openrgb
  ];

  services.hardware.openrgb = {
    enable = true;
    package = pkgs.openrgb;
    startupProfile = "black.orp";
    motherboard = "amd";
  };
}
