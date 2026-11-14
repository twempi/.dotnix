{
  flake.modules.homeManager.feh = {pkgs, ...}: {
    home.packages = [
      pkgs.feh
    ];

    stylix.targets.feh.enable = true;

    programs.feh = {
      enable = true;

      # Vim/zathura-style keys. Keys that were feh defaults for other actions move:
      # h -> toggle_pause is P, k -> toggle_keep_vp is K, z -> jump_random is X,
      # Z -> toggle_auto_zoom is T, d -> toggle_filenames is N.
      keybindings = {
        scroll_left = ["h" "C-Left" "KP_Left"];
        scroll_down = ["j" "C-Down" "KP_Down"];
        scroll_up = ["k" "C-Up" "KP_Up"];
        scroll_right = ["l" "C-Right" "KP_Right"];
        scroll_down_page = ["d" "1-Down"];
        scroll_up_page = ["u" "1-Up"];
        zoom_in = ["Up" "z" "KP_Add"];
        zoom_out = ["Down" "Z" "KP_Subtract"];
        zoom_fit = ["slash" "KP_Divide" "H"];
        reload_image = ["r" "C-r"];
        toggle_pause = "P";
        toggle_keep_vp = "K";
        toggle_filenames = "N";
        toggle_auto_zoom = "T";
        jump_random = "X";
        jump_first = ["g" "Home"];
        jump_last = ["G" "End"];
      };
    };
  };
}
