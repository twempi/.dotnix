{pkgs, ...}: {
  home.packages = with pkgs; [
    hyprpicker
    grim
    grimblast
    slurp
    hyprlock
    awww
    cliphist
    wl-clipboard
    xdg-utils
    brightnessctl
    libnotify
    imagemagick
  ];
}
