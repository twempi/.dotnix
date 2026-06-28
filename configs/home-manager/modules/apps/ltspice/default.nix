{pkgs, ...}: {
  home.packages = with pkgs; [
    ltspice
  ];
}
