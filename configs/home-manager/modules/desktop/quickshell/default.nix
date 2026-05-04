{pkgs, ...}: {
  home.packages = with pkgs; [
    quickshell
  ];

  programs.quickshell = {
    enable = true;
  };
}
