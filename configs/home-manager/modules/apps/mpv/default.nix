{
  flake.modules.homeManager.mpv = {
    stylix.targets.mpv.enable = true;

    programs.mpv = {
      enable = true;

      config = {
        vo = "gpu-next";
        hwdec = "auto";
        save-position-on-quit = true;
        keep-open = true;
        # autofit-larger = "90%x90%";
        volume = 40;
        volume-max = 100;
        sub-auto = "fuzzy";
        slang = "en,eng";
        osd-duration = 2000;
      };

      bindings = {
        LEFT = "seek -5 relative+exact"; # Back 5 seconds
        RIGHT = "seek 5 relative+exact"; # Forward 5 seconds
        DOWN = "seek -15 relative+exact"; # Back 15 seconds
        UP = "seek 15 relative+exact"; # Forward 15 seconds
      };
    };
  };
}
