{
  inputs,
  system,
  ...
}: let
  mangoPackage = inputs.mangowm.packages.${system}.mango;
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
