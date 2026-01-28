{
  config,
  pkgs,
  ...
}: {
  services.syncthing = {
    enable = true;

    guiAddress = "127.0.0.1:8384";

    settings = {
      options = {
        localAnnounceEnabled = false; # eduroam blocks this anyway
        natEnabled = true;
        relaysEnabled = true; # important one
        globalAnnounceEnabled = true;
        startBrowser = false;
      };
    };
  };
}
