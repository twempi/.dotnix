{
  config,
  inputs,
  lib,
  ...
}: let
  userSettings = builtins.fromTOML (builtins.readFile ./settings.toml);
  colors = config.lib.stylix.colors.withHashtag;
  terminalPalette = with colors; {
    normal = {
      black = base00;
      red = base08;
      green = base0B;
      yellow = base0A;
      blue = base0D;
      magenta = base0E;
      cyan = base0C;
      white = base05;
    };

    bright = {
      black = base03;
      red = base08;
      green = base0B;
      yellow = base0A;
      blue = base0D;
      magenta = base0E;
      cyan = base0C;
      white = base07;
    };

    foreground = base05;
    background = base00;
    cursor = base05;
    cursorText = base00;
    selectionFg = base04;
    selectionBg = base01;
  };
  stylixPalette =
    (with colors; {
      mPrimary = base0D;
      mOnPrimary = base00;
      mSecondary = base0E;
      mOnSecondary = base00;
      mTertiary = base0C;
      mOnTertiary = base00;
      mError = base08;
      mOnError = base00;
      mSurface = base00;
      mOnSurface = base05;
      mHover = base0C;
      mOnHover = base00;
      mSurfaceVariant = base01;
      mOnSurfaceVariant = base04;
      mOutline = base03;
      mShadow = base00;
    })
    // {
      terminal = terminalPalette;
    };
  stylixSettings = {
    shell = {
      font_family = config.stylix.fonts.sansSerif.name;
      launch_apps_as_systemd_services = true;
      settings_show_advanced = true;
    };

    theme = {
      mode =
        if config.stylix.polarity == "light"
        then "light"
        else "dark";
      source = "custom";
      custom_palette = "stylix";
    };

    bar.default = {
      background_opacity = config.stylix.opacity.desktop;
      capsule_opacity = config.stylix.opacity.desktop;
    };

    dock.background_opacity = config.stylix.opacity.desktop;
    osd.background_opacity = config.stylix.opacity.popups;
    notification.background_opacity = config.stylix.opacity.popups;
  };
in {
  imports = [
    inputs.noctalia.homeModules.default
  ];

  programs.noctalia = {
    enable = true;
    systemd.enable = false;

    settings = lib.recursiveUpdate userSettings stylixSettings;

    customPalettes = {
      stylix = {
        dark = stylixPalette;
        light = stylixPalette;
      };
    };
  };
}
