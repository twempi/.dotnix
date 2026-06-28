{pkgs, ...}: {
  home.packages = with pkgs; [
    seahorse
  ];
}
