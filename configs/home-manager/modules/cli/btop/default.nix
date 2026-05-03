{lib, ...}: {
  programs.btop = {
    enable = true;
    settings = {
      color_theme = lib.mkForce "TTY";
      vim_keys = true;
    };
  };
}
