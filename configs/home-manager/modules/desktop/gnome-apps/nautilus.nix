{
  pkgs,
  config,
  ...
}: let
  home = config.home.homeDirectory;
in {
  home.packages = with pkgs; [
    nautilus
  ];

  # Standard user directories
  xdg.userDirs = {
    enable = true;
    createDirectories = true;

    desktop = "${home}/Desktop";
    documents = "${home}/Documents";
    download = "${home}/Downloads";
    music = "${home}/Music";
    pictures = "${home}/Pictures";
    videos = "${home}/Videos";
  };

  # Nautilus sidebar bookmarks
  xdg.configFile."gtk-3.0/bookmarks" = {
    force = true;
    text = ''
      file://${home}/Desktop Desktop
      file://${home}/Downloads Downloads
      file://${home}/Documents Documents
      file://${home}/Pictures Pictures
      file://${home}/Music Music
      file://${home}/Videos Videos
    '';
  };
}
