{
  stylix.targets.kitty = {
    enable = true;
    fonts = {
      enable = true;
      # override = "Geist Mono";
    };
    opacity = {
      enable = true;
      override = {
        terminal = 0.8;
      };
    };
    variant256Colors = true;
  };

  programs.kitty = {
    enable = true;

    # extraConfig = ''
    #   include matugen.conf
    # '';

    # font = {
    #   name = lib.mkForce "Geist Mono";
    #   size = 11;
    # };

    settings = {
      bold_font = "false";
      italic_font = "auto";
      bold_italic_font = "auto";
      remember_window_size = "no";
      initial_window_width = "950";
      initial_window_height = "500";
      cursor_blink_interval = "0.5";
      cursor_stop_blinking_after = "1";
      scrollback_lines = "2000";
      wheel_scroll_min_lines = "1";
      enable_audio_bell = "no";
      window_padding_width = "10";
      hide_window_decorations = "yes";
      # background_opacity = lib.mkForce "0.8";
      dynamic_background_opacity = "yes";
      confirm_os_window_close = "0";
      selection_foreground = "none";
      selection_background = "none";
      allow_remote_control = "yes";
    };
  };
}
