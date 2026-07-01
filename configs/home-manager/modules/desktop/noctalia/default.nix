{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) system;

  noctaliaPackage = inputs.noctalia.packages.${system}.default;
  jsonFormat = pkgs.formats.json {};
  windowManagers = [
    "hyprland"
    "sway"
    "mango"
  ];

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
  stylixPaletteSource =
    jsonFormat.generate "stylix-palette.json" {
      dark = stylixPalette;
      light = stylixPalette;
    };
<<<<<<< HEAD
  settingsFor = wm:
    let
      settings =
        lib.recursiveUpdate
        (lib.recursiveUpdate baseSettings stylixSettings)
        wmSettings.${wm};
      extraPlugins = config.edward.noctalia.extraEnabledPlugins;
      extraSettings =
        {
          shell.session.actions = (settings.shell.session.actions or []) ++ config.edward.noctalia.extraSessionActions;
        }
        // lib.optionalAttrs (extraPlugins != []) {
          plugins.enabled = lib.unique ((settings.plugins.enabled or []) ++ extraPlugins);
        };
    in
      lib.recursiveUpdate settings extraSettings;
=======
>>>>>>> 4f91ef4 ( feat: ✨ updated system with new noctalia shell config)
  configSourceFor = wm: let
    rawConfig = ./configs + "/${wm}.toml";
  in
    if config.programs.noctalia.validateConfig
    then
      pkgs.runCommand "noctalia-${wm}-config" {} ''
        ${lib.getExe noctaliaPackage} config validate ${rawConfig}
        cp ${rawConfig} $out
      ''
    else rawConfig;
  wrapperFor = wm:
    pkgs.writeShellApplication {
      name = "noctalia-${wm}";
      text = ''
        exec env \
          NOCTALIA_CONFIG_HOME="${config.xdg.configHome}/noctalia-${wm}" \
          NOCTALIA_STATE_HOME="${config.xdg.stateHome}/noctalia-${wm}" \
          NOCTALIA_DATA_HOME="${config.xdg.dataHome}/noctalia-${wm}" \
          ${lib.getExe noctaliaPackage} "$@"
      '';
    };
  wrappers = lib.genAttrs windowManagers wrapperFor;
  wrapperCommands = lib.mapAttrs (wm: package: "${package}/bin/noctalia-${wm}") wrappers;
  configFiles =
    lib.mkMerge (
      map (wm: {
        "noctalia-${wm}/noctalia/config.toml".source = configSourceFor wm;
        "noctalia-${wm}/noctalia/palettes/stylix.json".source = stylixPaletteSource;
      })
      windowManagers
    );
in {
  imports = [
    inputs.noctalia.homeModules.default
  ];

  options.edward.noctalia.commands = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    default = {};
    description = "Noctalia wrapper commands keyed by window manager.";
  };

<<<<<<< HEAD
  options.edward.noctalia.extraSessionActions = lib.mkOption {
    type = lib.types.listOf (lib.types.attrsOf lib.types.anything);
    default = [];
    description = "Extra Noctalia session panel actions appended to each window-manager config.";
  };

  options.edward.noctalia.extraEnabledPlugins = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [];
    description = "Extra Noctalia plugin ids enabled in each generated window-manager config.";
  };

=======
>>>>>>> 4f91ef4 ( feat: ✨ updated system with new noctalia shell config)
  config = {
    edward.noctalia.commands = wrapperCommands;

    programs.noctalia = {
      enable = true;
      systemd.enable = false;
    };

    home.packages = builtins.attrValues wrappers;

    xdg.configFile = configFiles;
  };
}
