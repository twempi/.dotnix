{
  # Mounting additional drives
  fileSystems = let
    ntfsOptions = [
      "rw"
      "uid=1000"
      "gid=100"
      "umask=000"
      "exec"
      "nofail"
      "noatime"
      "x-systemd.automount"
      "windows_names"
    ];
  in {
    "/mnt/Storage" = {
      device = "/dev/disk/by-uuid/9A62A5A562A5871B";
      fsType = "ntfs3";
      options = ntfsOptions;
    };

    "/mnt/Windows" = {
      device = "/dev/disk/by-uuid/01DC4262B6A13A40";
      fsType = "ntfs3";
      options = ntfsOptions;
    };

    "/home/edward/Documents/notes" = {
      device = "/mnt/Storage/Documents/notes";
      fsType = "none";
      options = ["bind" "rw" "nofail"];
      depends = ["/mnt/Storage"];
    };

    "/home/edward/Documents/school" = {
      device = "/mnt/Storage/Documents/school";
      fsType = "none";
      options = ["bind" "rw" "nofail"];
      depends = ["/mnt/Storage"];
    };
  };
}
