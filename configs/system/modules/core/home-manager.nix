{
  inputs,
  system,
  hostname,
  lib,
  ...
}: let
  entertainmentHosts = ["t480s"];
  desktopHosts = ["desktop" "g14"];
  graphicalHosts = entertainmentHosts ++ desktopHosts;
  profileModule =
    if builtins.elem hostname entertainmentHosts
    then ../../../home-manager/profiles/entertainment.nix
    else ../../../home-manager/profiles/desktop.nix;
in {
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
          profileModule
          (../../../hosts + "/${hostname}/home/modules.nix")
        ]
        ++ lib.optionals (builtins.elem hostname graphicalHosts) [
          inputs.spicetify-nix.homeManagerModules.default
        ];
    };
  };
}
