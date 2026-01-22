{
  pkgs,
  lib,
  config,
  ...
}: {
  services.syncthing = {
    enable = true;

    dataDir = "${config.home.homeDirectory}/Documents/syncthing";

    guiAddress = "127.0.0.1:8384";

    settings = {
      options = {
        localAnnounceEnabled = false; # eduroam blocks this anyway
        natEnabled = true;
        relaysEnabled = true; # THIS is the important one
        globalAnnounceEnabled = true;
        startBrowser = false;
      };
    };
  };
}
