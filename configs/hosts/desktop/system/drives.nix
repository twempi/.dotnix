{
  config,
  pkgs,
  ...
}: {
  # Mounting additional drives
  fileSystems = {
    "/mnt/Storage" = {
      device = "/dev/disk/by-uuid/9A62A5A562A5871B";
      fsType = "ntfs-3g";
      options = ["rw" "uid=1000" "gid=100" "dmask=022" "fmask=133" "exec" "nofail"];
    };

    "/mnt/Windows" = {
      device = "/dev/disk/by-uuid/01DC4262B6A13A40";
      fsType = "ntfs-3g";
      options = ["rw" "uid=1000" "nofail" "gid=100" "dmask=022" "fmask=133"];
    };
  };
}
