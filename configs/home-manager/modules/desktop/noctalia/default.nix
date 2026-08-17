{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  inherit (pkgs.stdenv.hostPlatform) system;

  noctaliaPackage = inputs.noctalia.packages.${system}.default;
  windowManagers = [
    "hyprland"
    "sway"
    "mango"
  ];

  stylixColors = config.lib.stylix.colors.withHashtag;
  nativeStylixConfig = config.xdg.configFile."noctalia/config.toml".source;
  nativeStylixPalette = config.xdg.configFile."noctalia/palettes/stylix.json".source;
  configSourceFor = wm: let
    rawConfig = ./configs + "/${wm}.toml";
    resolvedRawConfig =
      if lib.elem wm ["sway" "mango"]
      then
        pkgs.replaceVars rawConfig (
          {
            inherit
              (stylixColors)
              base09
              base0A
              base0B
              base0C
              base0D
              base0E
              ;
          }
          // lib.optionalAttrs (wm == "sway") {
            inherit (stylixColors) base08;
          }
        )
      else rawConfig;
    extraConfig = config.edward.noctalia.extraConfigText.${wm} or "";
    mergedConfig =
      if extraConfig == ""
      then resolvedRawConfig
      else
        pkgs.concatText "noctalia-${wm}.toml" [
          resolvedRawConfig
          (pkgs.writeText "noctalia-${wm}-extra.toml" "\n\n${extraConfig}\n")
        ];
  in
    if config.programs.noctalia.validateConfig
    then
      pkgs.runCommand "noctalia-${wm}-config" {} ''
        config_dir="$TMPDIR/noctalia-${wm}"
        mkdir -p "$config_dir"
        cp ${mergedConfig} "$config_dir/config.toml"
        cp ${nativeStylixConfig} "$config_dir/stylix.toml"
        ${lib.getExe noctaliaPackage} config validate "$config_dir"
        cp ${mergedConfig} "$out"
      ''
    else mergedConfig;
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
  configFiles = lib.mkMerge (
    map (wm: {
      "noctalia-${wm}/noctalia/config.toml".source = configSourceFor wm;
      "noctalia-${wm}/noctalia/stylix.toml".source = nativeStylixConfig;
      "noctalia-${wm}/noctalia/palettes/stylix.json".source = nativeStylixPalette;
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

  options.edward.noctalia.extraConfigText = lib.mkOption {
    type = lib.types.attrsOf lib.types.lines;
    default = {};
    description = "Extra Noctalia TOML appended to wrapper configs by window manager.";
  };

  config = {
    edward.noctalia.commands = wrapperCommands;

    stylix.targets.noctalia.enable = true;

    programs.noctalia = {
      enable = true;
      systemd.enable = false;
    };

    home.packages = builtins.attrValues wrappers;

    xdg.configFile = configFiles;
  };
}
