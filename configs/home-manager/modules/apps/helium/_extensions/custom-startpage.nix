{
  config,
  hostname,
  inputs,
  pkgs,
  startpageOrigin,
}: let
  startpage = inputs.twempi.packages.${pkgs.stdenv.hostPlatform.system}.startpage;
in
  # Only pass arguments the pinned twempi package accepts, so `hostname`
  # switches on by itself once the twempi lock includes it.
  startpage.override (builtins.intersectAttrs (pkgs.lib.functionArgs startpage.override) {
    colors = config.lib.stylix.colors;
    fontFamily = config.stylix.fonts.monospace.name;
    sansFontFamily = config.stylix.fonts.sansSerif.name;
    inherit hostname startpageOrigin;
  })
