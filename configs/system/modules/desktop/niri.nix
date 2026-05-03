{pkgs, ...}: {
  programs = {
    niri.enable = true;
  };

  xdg.portal.config.niri.default = ["gnome" "gtk"];
}
