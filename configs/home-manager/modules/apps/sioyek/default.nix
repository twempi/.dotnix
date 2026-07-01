{pkgs, ...}: {
  home.packages = with pkgs; [sioyek];

  stylix.targets.sioyek = {
    enable = true;
    colors.enable = true;
  };

  programs.sioyek = {
    enable = true;
    # config = {
    # startup_commands = {
    # };
    # };
    # keybinds = {
    # };
  };
}
