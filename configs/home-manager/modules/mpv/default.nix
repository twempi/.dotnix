{
  stylix.targets.mpv.enable = true;

  programs.mpv = {
    enable = true;
    config = {
      hwdec = "auto";
      profile = "fast";
      vo = "gpu";
      gpu-context = "wayland";
      interpolation = "no";
      deband = "no";
      video-sync = "audio";
      save-position-on-quit = "yes";
      keep-open = "yes";
    };
  };

  xdg.configFile."mpv/scripts" = {
    source = ./mpv/scripts;
    recursive = true;
  };
}
