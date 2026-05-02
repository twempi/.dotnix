{
  inputs,
  system,
  hostname,
  ...
}: {
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "hm-backup";

    extraSpecialArgs = {
      inherit inputs system hostname;
    };

    users.edward = {
      imports = [
        ../../home-manager/home.nix
        (../../hosts + "/${hostname}/home/modules.nix")
        inputs.stylix.homeModules.stylix
        inputs.spicetify-nix.homeManagerModules.default
        inputs.niri.homeModules.config
        inputs.niri.homeModules.stylix
      ];
    };
  };
}
