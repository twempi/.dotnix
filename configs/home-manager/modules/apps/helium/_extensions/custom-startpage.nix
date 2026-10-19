{
  config,
  inputs,
  pkgs,
  startpageOrigin,
}:
inputs.twempi.packages.${pkgs.stdenv.hostPlatform.system}.startpage.override {
  colors = config.lib.stylix.colors;
  fontFamily = config.stylix.fonts.monospace.name;
  sansFontFamily = config.stylix.fonts.sansSerif.name;
  inherit startpageOrigin;
}
