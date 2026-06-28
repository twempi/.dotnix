{pkgs, ...}: {
  home.packages = with pkgs; [
    nautilus
    eog
    gnome-calculator
  ];
}
