{pkgs, ...}: {
  programs.quickshell = {
    enable = true;
  };

  xdg.configFile."hypr/scripts".source = ./scripts;
}
