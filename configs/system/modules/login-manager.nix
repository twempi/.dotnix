{
  pkgs,
  lib,
  config,
  ...
}: {
  services.displayManager.ly = {
    enable = true;
    # settings = {
    # };
  };
}
