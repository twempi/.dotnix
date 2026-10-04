{pkgs, ...}: {
  environment.systemPackages = [
    pkgs.openrgb
  ];

  services.hardware.openrgb = {
    enable = true;
    package = pkgs.openrgb;
    startupProfile = "profiles/black.json";
    motherboard = "amd";
  };
}
