{
  config,
  lib,
  pkgs,
  ...
}: let
  colors = config.lib.stylix.colors.withHashtag;
  polarity = config.stylix.polarity;

  notesDir = "${config.home.homeDirectory}/Documents/notes";

  stylixThemeManifest = pkgs.writeText "obsidian-stylix-manifest.json" ''
    {
      "name": "Stylix",
      "version": "1.0.0",
      "minAppVersion": "1.0.0",
      "author": "Stylix"
    }
  '';

  stylixThemeCss = pkgs.writeText "obsidian-stylix-theme.css" ''
    .theme-${polarity} {
      /* Base palette */
      --color-base-00: ${colors.base00};
      --color-base-05: ${colors.base00};
      --color-base-10: ${colors.base00};
      --color-base-20: ${colors.base01};
      --color-base-25: ${colors.base01};
      --color-base-30: ${colors.base02};
      --color-base-35: ${colors.base02};
      --color-base-40: ${colors.base03};
      --color-base-50: ${colors.base03};
      --color-base-60: ${colors.base04};
      --color-base-70: ${colors.base04};
      --color-base-100: ${colors.base05};

      /* Accent */
      --color-accent: ${colors.base0E};
      --color-accent-1: ${colors.base0E};
      --color-accent-2: ${colors.base0D};

      --interactive-accent: ${colors.base0E};
      --interactive-accent-hover: ${colors.base0D};

      /* Backgrounds */
      --background-primary: ${colors.base00};
      --background-primary-alt: ${colors.base01};
      --background-secondary: ${colors.base01};
      --background-secondary-alt: ${colors.base02};
      --background-modifier-border: ${colors.base03};
      --background-modifier-border-hover: ${colors.base04};
      --background-modifier-border-focus: ${colors.base0E};
      --background-modifier-hover: ${colors.base02};
      --background-modifier-active-hover: ${colors.base03};
      --background-modifier-form-field: ${colors.base01};
      --background-modifier-form-field-highlighted: ${colors.base02};
      --background-modifier-box-shadow: ${colors.base00};
      --background-modifier-success: ${colors.base0B};
      --background-modifier-error: ${colors.base08};
      --background-modifier-error-hover: ${colors.base08};

      /* Text */
      --text-normal: ${colors.base05};
      --text-muted: ${colors.base04};
      --text-faint: ${colors.base03};
      --text-accent: ${colors.base0D};
      --text-accent-hover: ${colors.base0E};
      --text-on-accent: ${colors.base00};
      --text-error: ${colors.base08};
      --text-error-hover: ${colors.base08};
      --text-warning: ${colors.base0A};
      --text-success: ${colors.base0B};
      --text-selection: ${colors.base02};

      /* Links */
      --link-color: ${colors.base0D};
      --link-color-hover: ${colors.base0E};
      --link-decoration: none;
      --link-decoration-hover: underline;
      --link-external-color: ${colors.base0C};
      --link-external-color-hover: ${colors.base0E};
      --link-external-decoration: none;
      --link-external-decoration-hover: underline;

      /* Headings */
      --h1-color: ${colors.base0E};
      --h2-color: ${colors.base0D};
      --h3-color: ${colors.base0C};
      --h4-color: ${colors.base0B};
      --h5-color: ${colors.base0A};
      --h6-color: ${colors.base09};

      /* Code */
      --code-background: ${colors.base01};
      --code-normal: ${colors.base05};
      --code-comment: ${colors.base04};
      --code-function: ${colors.base0D};
      --code-important: ${colors.base0E};
      --code-keyword: ${colors.base0E};
      --code-operator: ${colors.base0C};
      --code-property: ${colors.base0A};
      --code-punctuation: ${colors.base04};
      --code-string: ${colors.base0B};
      --code-tag: ${colors.base08};
      --code-value: ${colors.base09};

      /* Quotes, tables, tags */
      --blockquote-border-color: ${colors.base0E};
      --blockquote-background-color: ${colors.base01};

      --table-border-color: ${colors.base03};
      --table-header-background: ${colors.base01};
      --table-row-background-hover: ${colors.base02};

      --tag-color: ${colors.base0E};
      --tag-background: ${colors.base01};
      --tag-background-hover: ${colors.base02};

      /* Checkboxes */
      --checkbox-color: ${colors.base0E};
      --checkbox-color-hover: ${colors.base0D};
      --checkbox-marker-color: ${colors.base00};
      --checkbox-border-color: ${colors.base04};
      --checkbox-border-color-hover: ${colors.base0E};

      /* Navigation / sidebars */
      --nav-item-color: ${colors.base04};
      --nav-item-color-hover: ${colors.base05};
      --nav-item-color-active: ${colors.base05};
      --nav-item-background-hover: ${colors.base02};
      --nav-item-background-active: ${colors.base02};

      /* Prompts / modals */
      --modal-background: ${colors.base00};
      --prompt-border-color: ${colors.base03};

      /* Scrollbars */
      --scrollbar-bg: ${colors.base00};
      --scrollbar-thumb-bg: ${colors.base03};
      --scrollbar-active-thumb-bg: ${colors.base04};

      /* Graph view */
      --graph-line: ${colors.base03};
      --graph-node: ${colors.base0D};
      --graph-node-unresolved: ${colors.base08};
      --graph-node-focused: ${colors.base0E};
      --graph-node-tag: ${colors.base0B};
      --graph-node-attachment: ${colors.base0A};
    }
  '';
in {
  home.activation.obsidianStylixTheme = lib.hm.dag.entryAfter ["writeBoundary"] ''
    obsidian_dir=${lib.escapeShellArg "${notesDir}/.obsidian"}
    theme_dir="$obsidian_dir/themes/Stylix"
    appearance_file="$obsidian_dir/appearance.json"

    verboseEcho "Installing Obsidian Stylix theme to $theme_dir"

    run mkdir -p "$theme_dir"

    run install -m644 ${lib.escapeShellArg "${stylixThemeManifest}"} \
      "$theme_dir/manifest.json"

    run install -m644 ${lib.escapeShellArg "${stylixThemeCss}"} \
      "$theme_dir/theme.css"

    if [ ! -f "$appearance_file" ]; then
      run mkdir -p "$obsidian_dir"
      echo '{}' > "$appearance_file"
    fi

    tmp_file="$(mktemp)"

    ${pkgs.jq}/bin/jq \
      --arg cssTheme "Stylix" \
      --arg baseColor ${lib.escapeShellArg polarity} \
      '
        .cssTheme = $cssTheme
        | .baseColor = $baseColor
      ' "$appearance_file" > "$tmp_file"

    run install -m644 "$tmp_file" "$appearance_file"
    rm "$tmp_file"
  '';

  xdg.desktopEntries.obsidian = {
    name = "Obsidian";
    exec = "${pkgs.obsidian}/bin/obsidian %U";
    icon = "obsidian";
    terminal = false;
    categories = ["Office"];
    mimeType = ["x-scheme-handler/obsidian"];
  };
}
