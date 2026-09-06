{pkgs, ...}: {
  home.packages = with pkgs; [
    handy
    wtype
    xdotool
  ];
}
