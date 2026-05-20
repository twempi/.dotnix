{
  inputs,
  pkgs,
  system,
  ...
}: let
  mangoPackage = import ../../../home-manager/modules/desktop/de/mango/mango-patched.nix {
    inherit inputs pkgs system;
  };
in {
  imports = [
    inputs.mangowm.nixosModules.mango
  ];
  programs = {
    mango = {
      enable = true;
      package = mangoPackage;
    };
  };

  xdg.portal.config.mangowm.default = ["wlr" "gtk"];
}
