{pkgs, ...}: {
  home.packages = with pkgs; [
    libimobiledevice
    ifuse
  ];
}
