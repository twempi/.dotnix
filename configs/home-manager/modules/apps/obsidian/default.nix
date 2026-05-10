{
  config,
  lib,
  pkgs,
  hostname,
  ...
}: let
  colors = config.lib.stylix.colors;
  fonts = config.stylix.fonts;

  notesDir =
    if hostname == "desktop"
    then "/mnt/Storage/Documents/notes"
    else "${config.home.homeDirectory}/Documents/notes";

  stylixThemeManifest = pkgs.writeText "obsidian-stylix-manifest.json" (builtins.toJSON {
    name = "Stylix";
    version = "1.0.0";
    minAppVersion = "1.0.0";
    author = "Stylix";
  });

  stylixThemeCss = pkgs.writeText "obsidian-stylix-theme.css" ''
    .theme-dark,
    .theme-light {
      --color-base-00: #${colors.base00};
      --color-base-05: #${colors.base00};
      --color-base-10: #${colors.base00};
      --color-base-20: #${colors.base01};
      --color-base-25: #${colors.base01};
      --color-base-30: #${colors.base02};
      --color-base-35: #${colors.base02};
      --color-base-40: #${colors.base03};
      --color-base-50: #${colors.base03};
      --color-base-60: #${colors.base04};
      --color-base-70: #${colors.base04};
      --color-base-100: #${colors.base05};

      --color-accent: #${colors.base0E};
      --color-accent-1: #${colors.base0E};
      --color-accent-2: #${colors.base0D};

      --background-primary: #${colors.base00};
      --background-primary-alt: #${colors.base01};
      --background-secondary: #${colors.base01};
      --background-secondary-alt: #${colors.base02};
      --background-modifier-border: #${colors.base03};
      --background-modifier-hover: #${colors.base02};
      --background-modifier-active-hover: #${colors.base03};

      --text-normal: #${colors.base05};
      --text-muted: #${colors.base04};
      --text-faint: #${colors.base03};
      --text-accent: #${colors.base0D};
      --text-accent-hover: #${colors.base0E};
      --text-error: #${colors.base08};
      --text-warning: #${colors.base0A};
      --link-color: #${colors.base0D};
      --link-color-hover: #${colors.base0E};
      --link-external-color: #${colors.base0C};
      --link-external-color-hover: #${colors.base0E};

      --code-background: #${colors.base01};
      --code-normal: #${colors.base05};
      --code-comment: #${colors.base04};
      --code-function: #${colors.base0D};
      --code-important: #${colors.base0E};
      --code-keyword: #${colors.base0E};
      --code-operator: #${colors.base0C};
      --code-property: #${colors.base0A};
      --code-punctuation: #${colors.base04};
      --code-string: #${colors.base0B};
      --code-tag: #${colors.base08};
      --code-value: #${colors.base09};

      --blockquote-border-color: #${colors.base0E};
      --interactive-accent: #${colors.base0E};
      --interactive-accent-hover: #${colors.base0D};
      --scrollbar-thumb-bg: #${colors.base03};
      --scrollbar-active-thumb-bg: #${colors.base04};

      # --font-interface: "${fonts.sansSerif.name}";
      # --font-text: "${fonts.serif.name}";
      # --font-monospace: "${fonts.monospace.name}";
    }
  '';
in {
  home.activation.obsidianStylixTheme = lib.hm.dag.entryAfter ["writeBoundary"] ''
    theme_dir=${lib.escapeShellArg "${notesDir}/.obsidian/themes/Stylix"}
    verboseEcho "Installing Obsidian Stylix theme to $theme_dir"
    run mkdir -p "$theme_dir"
    run install -m644 ${lib.escapeShellArg "${stylixThemeManifest}"} "$theme_dir/manifest.json"
    run install -m644 ${lib.escapeShellArg "${stylixThemeCss}"} "$theme_dir/theme.css"
  '';
}
