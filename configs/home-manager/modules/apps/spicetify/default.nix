{
  inputs,
  pkgs,
  lib,
  ...
}: let
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in {
  # stylix.targets.spicetify.enable = true;

  programs.spicetify = {
    enable = true;
    enabledExtensions = with spicePkgs.extensions; [
      adblock
      keyboardShortcut
      hidePodcasts
      fullScreen
    ];
    enabledCustomApps = with spicePkgs.apps; [
      lyricsPlus
    ];
    theme = spicePkgs.themes.text;
    # colorScheme = "RosePine";
    # colorScheme = "Gruvbox";
    colorScheme = "CatppuccinMocha";
  };
}
