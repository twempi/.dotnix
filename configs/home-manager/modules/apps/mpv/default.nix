{
  stylix.targets.mpv.enable = true;

  programs.mpv = {
    enable = true;
  };

  xdg.configFile."mpv/scripts" = {
    source = ./mpv/scripts;
    recursive = true;
  };
}
