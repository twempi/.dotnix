{pkgs, config, ...}: {
  stylix.targets.gtk.enable = true;

  gtk.iconTheme = {
    name = "Papirus-Dark";
    package = pkgs.papirus-icon-theme.override {
      color = "black";
    };
  };

  gtk.gtk4.theme = config.gtk.theme;
}
