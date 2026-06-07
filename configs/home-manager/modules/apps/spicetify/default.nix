{
  config,
  inputs,
  pkgs,
  ...
}: let
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
  colors = config.lib.stylix.colors;
in {
  # stylix.targets.spicetify.enable = true;

  programs.spicetify = {
    enable = true;
    wayland = true;
    alwaysEnableDevTools = true;

    spotifyLaunchFlags = " --remote-debugging-port=9222 --remote-debugging-address=127.0.0.1";

    enabledExtensions = with spicePkgs.extensions; [
      # adblock
      # autoSkipVideo
      keyboardShortcut
      hidePodcasts
      savePlaylists
      fullScreen
    ];

    enabledCustomApps = with spicePkgs.apps; [
      lyricsPlus
      # marketplace
    ];

    enabledSnippets = [
      (builtins.readFile ./snippets/spotify-overrides.css)
    ];

    theme = spicePkgs.themes.text;
    colorScheme = "custom";
    customColorScheme = {
      accent = colors.base0E;
      accent-active = colors.base0D;
      accent-inactive = colors.base00;
      banner = colors.base0E;
      border-active = colors.base0D;
      border-inactive = colors.base03;
      header = colors.base03;
      highlight = colors.base02;
      main = colors.base00;
      notification = colors.base0D;
      notification-error = colors.base08;
      subtext = colors.base04;
      text = colors.base05;
    };
  };
}
