{hostname, ...}: let
  isDesktop = hostname == "desktop";
  isServer = hostname == "t480s";

  mkFolder = name: devices: {
    id = name;
    inherit devices;

    path =
      if isDesktop
      then "/mnt/Storage/Documents/${name}"
      else "/home/edward/Documents/${name}";

    versioning =
      if isServer
      then {
        type = "staggered";
        params = {
          maxAge = "2592000"; # 30 days in seconds
        };
      }
      else null;
  };

  mkHeliumBookmarksFolder = devices: {
    id = "helium-bookmarks";
    label = "Helium Bookmarks";
    inherit devices;

    # This should be the Helium profile directory that contains:
    #   Bookmarks
    #   Bookmarks.bak
    path = "/home/edward/.config/net.imput.helium/Profile";

    # Keep backup versions on the t480s server.
    # Syncthing versioning applies per folder and stores replaced/deleted
    # files received from other devices.
    versioning =
      if isServer
      then {
        type = "staggered";
        params = {
          maxAge = "2592000"; # 30 days in seconds
        };
      }
      else null;
  };
in {
  # Create the .stignore on every NixOS device using this module.
  # .stignore itself is not synced by Syncthing, so it must exist locally
  # on desktop, g14, and t480s.
  system.activationScripts.heliumSyncthingIgnore.text = ''
        mkdir -p /home/edward/.config/net.imput.helium/Profile

        cat > /home/edward/.config/net.imput.helium/Profile/.stignore <<'EOF'
    !/Bookmarks
    !/Bookmarks.bak
    *
    EOF

        chown edward:users /home/edward/.config/net.imput.helium/Profile/.stignore
        chmod 0644 /home/edward/.config/net.imput.helium/Profile/.stignore
  '';

  services.syncthing = {
    enable = true;

    overrideFolders = true;
    overrideDevices = true;

    guiAddress = "127.0.0.1:8384";

    settings = {
      devices = {
        desktop.id = "ZMFIETG-MG7WV4P-2V6RHY4-JKDNXHB-X3INDKM-TSRFAVX-DARM2ZJ-XEBPQAZ";
        t480s.id = "QN7LOTX-BA4PZHR-CXZ47JH-POMXASY-6T4JPEW-3XEXAMH-77K4ACA-DONSCAX";
        g14.id = "AN7LFNP-RPK5BQO-77CE7SD-QQNPBQF-CLXRNSG-INK6UB5-QTZUPEY-AVKNAAC";
        ipad.id = "QONGDX6-P66XI6N-6O5HMZW-HYP52S6-YFLAMBD-ZIDVAIE-DYFIFGF-7FULZQG";
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
        notes = mkFolder "notes" ["desktop" "t480s" "g14" "ipad"];
        school = mkFolder "school" ["desktop" "t480s" "g14"];

        "helium-bookmarks" = mkHeliumBookmarksFolder [
          "desktop"
          "t480s"
          "g14"
        ];
      };
    };
  };
}
