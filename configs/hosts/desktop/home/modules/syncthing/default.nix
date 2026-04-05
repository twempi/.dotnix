{lib, ...}: {
  services.syncthing.settings.folders = {
    notes.path = lib.mkForce "/mnt/Storage/Documents/notes";
    school.path = lib.mkForce "/mnt/Storage/Documents/school";
  };
}
