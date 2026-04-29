{pkgs, ...}: {
  stylix.targets.mpv.enable = true;

  programs.mpv = {
    enable = true;
    package = pkgs.mpv-unwrapped;
  };

  xdg.configFile."mpv/scripts" = {
    source = ./mpv/scripts;
    recursive = true;
  };
}
