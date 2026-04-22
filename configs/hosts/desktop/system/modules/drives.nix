{
  # Mounting additional drives
  fileSystems = {
    "/mnt/Storage" = {
      device = "/dev/disk/by-uuid/9A62A5A562A5871B";
      fsType = "ntfs-3g";
      options = [
        "rw"
        "uid=1000"
        "gid=100"
        "umask=000"
        "exec"
        "nofail"
      ];
    };

    "/mnt/Windows" = {
      device = "/dev/disk/by-uuid/01DC4262B6A13A40";
      fsType = "ntfs-3g";
      options = [
        "rw"
        "uid=1000"
        "gid=100"
        "umask=000"
        "exec"
        "nofail"
      ];
    };

    "/home/edward/Documents/notes" = {
      device = "/mnt/Storage/Documents/notes";
      fsType = "none";
      options = [ "bind" ];
      depends = [ "/mnt/Storage" ];
    };
  };
}
