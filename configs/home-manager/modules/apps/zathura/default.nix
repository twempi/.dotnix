{lib, ...}: {
  stylix.targets.zathura = {
    enable = true;
  };
  programs.zathura = {
    enable = true;

    options = {
      selection-clipboard = "clipboard";
      incremental-search = true;
      search-hadjust = true;
      adjust-open = "width";
      font = "FiraCode Nerd Font 11";
      guioptions = "none";

      recolor = true;
      recolor-images = false;
    };

    mappings = {
      "[normal] z" = "zoom in";
      "[normal] Z" = "zoom out";
      "[fullscreen] z" = "zoom in";
      "[fullscreen] Z" = "zoom out";

      "[normal] D" = "toggle_page_mode";
      "[fullscreen] D" = "toggle_page_mode";

      "[normal] u" = "scroll half-up";
      "[normal] d" = "scroll half-down";
      "[fullscreen] u" = "scroll half-up";
      "[fullscreen] d" = "scroll half-down";

      "[normal] f" = "toggle_fullscreen";
      "[fullscreen] f" = "toggle_fullscreen";

      "[normal] <C-r>" = "reload";
      "[fullscreen] <C-r>" = "reload";

      "[normal] b" = "toggle_statusbar";
      "[fullscreen] b" = "toggle_statusbar";

      "[normal] H" = "adjust_window best-fit";
      "[normal] W" = "adjust_window width";
      "[fullscreen] H" = "adjust_window best-fit";
      "[fullscreen] W" = "adjust_window width";

      "[normal] i" = "set recolor";
      "[fullscreen] i" = "set recolor";
    };
  };
}
