{pkgs, ...}: {
  home.packages = with pkgs; [
    bleachbit
  ];
}
