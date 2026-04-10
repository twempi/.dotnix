{
  pkgs,
  lib,
  config,
  ...
}: {
  sylix.targets.sioyek = {
    enable = true;
  };

  programs.sioyek = {
    enable = true;
    # startup_commands = {
    # };
    # config = {
    # };
    # keybinds = {
    # };
  };
}
