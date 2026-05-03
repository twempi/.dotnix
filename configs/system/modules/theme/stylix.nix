{
  lib,
  pkgs,
  inputs,
  options,
  ...
}: let
  systemIntegration = lib.optionalAttrs (lib.hasAttrByPath ["stylix" "homeManagerIntegration"] options) {
    homeManagerIntegration = {
      autoImport = true;
      followSystem = true;
    };
  };
in {
  stylix = {
    enable = true;
    autoEnable = false;

    base16Scheme = inputs.tt-schemes + "/base16/rose-pine.yaml";
    polarity = "dark";

    cursor = {
      package = pkgs.quintom-cursor-theme;
      name = "Quintom_Ink";
      size = 24;
    };

    fonts = {
      monospace = {
        package = pkgs.fira-code;
        name = "Fira Code";
      };
      sansSerif = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Sans";
      };
      serif = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Serif";
      };
      sizes = {
        terminal = 11;
        applications = 11;
        desktop = 11;
        popups = 11;
      };
    };
  } // systemIntegration;
}
