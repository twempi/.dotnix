{hostname, ...}: let
  isDesktop = hostname == "desktop";
  isServer = hostname == "t480s";

  sharedDevices = ["desktop" "t480s" "g14"];

  mkFolder = name: {
    id = name;
    devices = sharedDevices;

    path =
      if isDesktop
      then "/mnt/Storage/Documents/${name}"
      else "/home/edward/Documents/${name}";

    versioning =
      if isServer
      then {
        type = "staggered";
        params = {
          maxAge = "2592000"; # 30 days
        };
      }
      else null;
  };
in {
  services.syncthing = {
    enable = true;

    overrideFolders = true;
    overrideDevices = true;

    guiAddress = "127.0.0.1:8384";

    settings = {
      devices = {
        desktop = {
          id = "ZMFIETG-MG7WV4P-2V6RHY4-JKDNXHB-X3INDKM-TSRFAVX-DARM2ZJ-XEBPQAZ";
        };

        t480s = {
          id = "QN7LOTX-BA4PZHR-CXZ47JH-POMXASY-6T4JPEW-3XEXAMH-77K4ACA-DONSCAX";
        };

        g14 = {
          id = "AN7LFNP-RPK5BQO-77CE7SD-QQNPBQF-CLXRNSG-INK6UB5-QTZUPEY-AVKNAAC";
        };
      };

      options = {
        localAnnounceEnabled = false;
        natEnabled = true;
        relaysEnabled = true;
        globalAnnounceEnabled = true;
        startBrowser = false;
        urAccepted = -1;
      };

      folders = {
        notes = mkFolder "notes";
        school = mkFolder "school";
      };
    };
  };
}
