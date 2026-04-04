{
  config,
  pkgs,
  ...
}: {
  # Boot settings
  boot = {
    loader = {
      grub = {
      };
    };
  };
  boot.supportedFilesystems = ["ntfs"];
}
