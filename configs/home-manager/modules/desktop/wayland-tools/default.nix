{pkgs, ...}: {
  home.packages = with pkgs; [
    hyprpicker
    xdg-utils
    brightnessctl
    imagemagick
  ];
}
