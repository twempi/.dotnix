{
  services.syncthing = {
    enable = true;

    guiAddress = "127.0.0.1:8384";

    settings = {
      devices = {
        desktop = {
          id = "ZMFIETG-MG7WV4P-2V6RHY4-JKDNXHB-X3INDKM-TSRFAVX-DARM2ZJ-XEBPQAZ";
        };

        # t480s = {
        #   id =
        # }
      };

      options = {
        localAnnounceEnabled = false; # eduroam blocks this anyway
        natEnabled = true;
        relaysEnabled = true; # important one
        globalAnnounceEnabled = true;
        startBrowser = false;
      };

      folders = {
        notes = {
          id = "notes";
          devices = ["desktop"];
          path = "/home/edward/Documents/notes";
        };
      };
    };
  };
}
