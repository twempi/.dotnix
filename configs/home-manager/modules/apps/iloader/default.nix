{pkgs, ...}: {
  home.packages = with pkgs; [
    iloader
  ];
}
