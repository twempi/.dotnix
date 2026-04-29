{pkgs, ...}: {
  home.packages = with pkgs; [
    quickshell
    jq
    socat
    pamixer
    brightnessctl
    wl-clipboard
    cliphist
    bluez
    networkmanager
    imagemagick
    qt6.qtmultimedia
    qt6.qt5compat
    qt6.qtwebsockets
    ffmpeg
  ];

  programs.quickshell = {
    enable = true;
  };

  xdg.configFile."hypr/scripts".source = ./scripts;
}
