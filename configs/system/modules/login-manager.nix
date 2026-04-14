{
  services.displayManager.ly = {
    enable = true;
    settings = {
      save = true;
      load = true;

      # UI
      clock = "%a %b %d  %H:%M";
      bigclock = "en";
      bigclock_seconds = true;
      hide_borders = false;
      box_title = "Welcome";
      default_input = "login";

      # Colors / layout
      bg = "0x00000000";
      border_fg = "0x00FFFFFF";
      blank_box = true;
      hide_key_hints = false;
      hide_version_string = false;
      show_tty = true;

      # Sessions / behavior
      shell = false;
      vi_mode = true;

      # Animation
      animation = "matrix";
      animation_timeout_sec = 0;
    };
  };
}
