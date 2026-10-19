{inputs, ...}: {
  # Hosts that manage edward through NixOS set `home-manager.users.edward`.
  flake.modules.nixos.home-manager = {
    imports = [inputs.home-manager.nixosModules.home-manager];

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      backupFileExtension = "hm-backup";
    };
  };
}
