{pkgs, ...}: {
  stylix.targets.kitty = {
    enable = true;

    fonts = {
      enable = true;
      override = {
        monospace = {
          package = pkgs.geist-font;
          name = "Geist Mono";
        };
        sizes = {
          terminal = 12;
        };
      };
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

    settings = {
      bold_font = "auto";
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
      dynamic_background_opacity = "yes";
      confirm_os_window_close = "0";
      selection_foreground = "none";
      selection_background = "none";
      allow_remote_control = "yes";
      cursor_trail = "1";
      cursor_trail_decay = "0.1 0.25";
      sync_to_monitor = "no";

      # Main rendering knob in kitty.
      # Start here for a thin/crisp look, then try:
      # "1.0 5", "1.0 8", or go back to "platform".
      text_composition_strategy = "1.0 0";
    };

    extraConfig = ''
      # Optional tiny tweaks if needed:
      modify_font baseline 1
      modify_font cell_width 98%
    '';
  };
}
