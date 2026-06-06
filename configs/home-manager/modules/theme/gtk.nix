{pkgs, ...}: {
  stylix.targets.gtk.enable = true;

  gtk.iconTheme = {
    name = "Papirus-Dark";
    package = pkgs.papirus-icon-theme.override {
      color = "black";
    };
  };
}
