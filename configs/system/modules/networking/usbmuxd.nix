{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    usbmuxd
    libimobiledevice
    ifuse
  ];
  services.usbmuxd.enable = true;
}
