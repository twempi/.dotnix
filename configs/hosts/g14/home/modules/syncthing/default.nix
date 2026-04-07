{lib, ...}: {
  services.syncthing.settings.folders = {
    notes.path = lib.mkForce "/home/edward/Documents/notes";
    school.path = lib.mkForce "/home/edward/Documents/school";
  };
}
