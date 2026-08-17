{pkgs, ...}: {
  imports = [
    ./nautilus.nix
  ];
  home.packages = with pkgs; [
    nautilus
    eog
    gnome-calculator
  ];
}
