{
  inputs,
  system,
  hostname,
  lib,
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
      imports =
        [
          (
            if hostname == "t480s"
            then ../../../home-manager/profiles/server.nix
            else ../../../home-manager/profiles/desktop.nix
          )
          (../../../hosts + "/${hostname}/home/modules.nix")
        ]
        ++ lib.optionals (hostname != "t480s") [
          inputs.spicetify-nix.homeManagerModules.default
          inputs.niri.homeModules.config
          inputs.niri.homeModules.stylix
        ];
    };
  };
}
