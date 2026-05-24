{
  pkgs,
  config,
  lib,
  ...
}: let
  colors = config.lib.stylix.colors.withHashtag;
  isDark = config.stylix.polarity == "dark";

  minimalSchemes = [
    "default"
    "atom"
    "ayu"
    "catppuccin"
    "dracula"
    "eink"
    "everforest"
    "flexoki"
    "gruvbox"
    "macos"
    "nord"
    "notion"
    "rose-pine"
    "solarized"
    "things"
  ];

  darkSchemes = lib.concatStringsSep ", " (map (scheme: ".minimal-${scheme}-dark") minimalSchemes);
  lightSchemes = lib.concatStringsSep ", " (map (scheme: ".minimal-${scheme}-light") minimalSchemes);

  darkStyles = lib.concatStringsSep ", " [
    ".minimal-dark"
    ".minimal-dark-tonal"
    ".minimal-dark-black"
  ];

  lightStyles = lib.concatStringsSep ", " [
    ".minimal-light"
    ".minimal-light-tonal"
    ".minimal-light-white"
    ".minimal-light-contrast"
  ];

  selectors = lib.concatStringsSep ",\n" [
    "body.theme-dark"
    "body.theme-light"
    "body.theme-dark:is(${darkSchemes})"
    "body.theme-light:is(${lightSchemes})"
    "body.theme-dark:is(${darkSchemes}):is(${darkStyles})"
    "body.theme-light:is(${lightSchemes}):is(${lightStyles})"
  ];

  hexByte = color: offset: lib.fromHexString (builtins.substring offset 2 color);
  hexToRgb = color: {
    r = hexByte color 1;
    g = hexByte color 3;
    b = hexByte color 5;
  };

  rgbTriplet = color: let
    rgb = hexToRgb color;
  in "${toString rgb.r}, ${toString rgb.g}, ${toString rgb.b}";

  abs = n:
    if n < 0
    then -n
    else n;

  max = a: b:
    if a > b
    then a
    else b;

  min = a: b:
    if a < b
    then a
    else b;

  max3 = a: b: c: max a (max b c);
  min3 = a: b: c: min a (min b c);
  round = n: builtins.floor (n + 0.5);

  rgbToHsl = color: let
    rgb = hexToRgb color;
    r = rgb.r / 255.0;
    g = rgb.g / 255.0;
    b = rgb.b / 255.0;
    high = max3 r g b;
    low = min3 r g b;
    delta = high - low;
    lightness = (high + low) / 2.0;
    saturation =
      if delta == 0
      then 0
      else delta / (1.0 - abs (2.0 * lightness - 1.0));
    hue =
      if delta == 0
      then 0
      else if high == r
      then 60.0 * (((g - b) / delta) + (if g < b then 6.0 else 0.0))
      else if high == g
      then 60.0 * (((b - r) / delta) + 2.0)
      else 60.0 * (((r - g) / delta) + 4.0);
  in {
    h = round hue;
    s = round (saturation * 100.0);
    l = round (lightness * 100.0);
  };

  baseColor =
    if isDark
    then colors.base01
    else colors.base00;
  accentColor = colors.base0D;
  baseHsl = rgbToHsl baseColor;
  accentHsl = rgbToHsl accentColor;

  bg1 =
    if isDark
    then "var(--stylix-base01)"
    else "var(--stylix-base00)";
  bg2 =
    if isDark
    then "var(--stylix-base00)"
    else "var(--stylix-base01)";
in
  pkgs.writeText "stylix-minimal.css" ''
    /*
      Stylix x Minimal

      Dynamic Minimal color scheme generated from the active Stylix palette.
      This snippet only sets CSS variables. It does not select the active
      Obsidian theme, switch Minimal presets, or enable snippets.
    */

    ${selectors} {
      /*
        Raw Stylix / Base16 palette.
      */

      --stylix-base00: ${colors.base00};
      --stylix-base01: ${colors.base01};
      --stylix-base02: ${colors.base02};
      --stylix-base03: ${colors.base03};
      --stylix-base04: ${colors.base04};
      --stylix-base05: ${colors.base05};
      --stylix-base06: ${colors.base06};
      --stylix-base07: ${colors.base07};
      --stylix-base08: ${colors.base08};
      --stylix-base09: ${colors.base09};
      --stylix-base0A: ${colors.base0A};
      --stylix-base0B: ${colors.base0B};
      --stylix-base0C: ${colors.base0C};
      --stylix-base0D: ${colors.base0D};
      --stylix-base0E: ${colors.base0E};
      --stylix-base0F: ${colors.base0F};

      --stylix-red: var(--stylix-base08);
      --stylix-orange: var(--stylix-base09);
      --stylix-yellow: var(--stylix-base0A);
      --stylix-green: var(--stylix-base0B);
      --stylix-cyan: var(--stylix-base0C);
      --stylix-blue: var(--stylix-base0D);
      --stylix-purple: var(--stylix-base0E);
      --stylix-pink: var(--stylix-base0F);

      /*
        Minimal color scheme anchors.
      */

      --base-h: ${toString baseHsl.h};
      --base-s: ${toString baseHsl.s}%;
      --base-l: ${toString baseHsl.l}%;
      --accent-h: ${toString accentHsl.h};
      --accent-s: ${toString accentHsl.s}%;
      --accent-l: ${toString accentHsl.l}%;

      --bg1: ${bg1};
      --bg2: ${bg2};
      --bg3: color-mix(in srgb, var(--stylix-base02) 72%, transparent);

      --ui1: color-mix(in srgb, var(--stylix-base02) 82%, var(--stylix-base03) 18%);
      --ui2: color-mix(in srgb, var(--stylix-base03) 72%, var(--stylix-base02) 28%);
      --ui3: color-mix(in srgb, var(--stylix-base04) 68%, var(--stylix-base03) 32%);

      --tx1: var(--stylix-base05);
      --tx2: var(--stylix-base04);
      --tx3: var(--stylix-base03);
      --tx4: var(--stylix-base06);

      --ax1: var(--stylix-base0D);
      --ax2: var(--stylix-base0E);
      --ax3: var(--stylix-base0C);

      --hl1: color-mix(in srgb, var(--ax1) 24%, transparent);
      --hl2: color-mix(in srgb, var(--stylix-base0A) 26%, transparent);
      --hl3: color-mix(in srgb, var(--ax2) 20%, transparent);
      --sp1: var(--stylix-base00);

      /*
        Minimal named palette.
      */

      --color-red-rgb: ${rgbTriplet colors.base08};
      --color-orange-rgb: ${rgbTriplet colors.base09};
      --color-yellow-rgb: ${rgbTriplet colors.base0A};
      --color-green-rgb: ${rgbTriplet colors.base0B};
      --color-cyan-rgb: ${rgbTriplet colors.base0C};
      --color-blue-rgb: ${rgbTriplet colors.base0D};
      --color-purple-rgb: ${rgbTriplet colors.base0E};
      --color-pink-rgb: ${rgbTriplet colors.base0F};

      --color-red: var(--stylix-base08);
      --color-orange: var(--stylix-base09);
      --color-yellow: var(--stylix-base0A);
      --color-green: var(--stylix-base0B);
      --color-cyan: var(--stylix-base0C);
      --color-blue: var(--stylix-base0D);
      --color-purple: var(--stylix-base0E);
      --color-pink: var(--stylix-base0F);

      /*
        Obsidian base ramp.
      */

      --color-base-00: color-mix(in srgb, var(--bg2) 94%, black 6%);
      --color-base-05: color-mix(in srgb, var(--bg2) 80%, var(--bg1) 20%);
      --color-base-10: var(--bg2);
      --color-base-20: var(--bg1);
      --color-base-25: color-mix(in srgb, var(--bg1) 86%, var(--ui1) 14%);
      --color-base-30: var(--ui1);
      --color-base-35: color-mix(in srgb, var(--ui1) 70%, var(--ui2) 30%);
      --color-base-40: var(--ui2);
      --color-base-50: var(--ui3);
      --color-base-60: var(--tx3);
      --color-base-70: var(--tx2);
      --color-base-100: var(--tx1);

      /*
        Obsidian core colors.
      */

      --background-primary: var(--bg1);
      --background-primary-alt: color-mix(in srgb, var(--bg1) 82%, var(--bg2) 18%);
      --background-secondary: var(--bg2);
      --background-secondary-alt: color-mix(in srgb, var(--bg2) 82%, var(--bg1) 18%);

      --background-modifier-border: var(--ui1);
      --background-modifier-border-hover: var(--ui2);
      --background-modifier-border-focus: var(--ax1);
      --background-modifier-hover: var(--bg3);
      --background-modifier-active-hover: color-mix(in srgb, var(--ax1) 12%, transparent);
      --background-modifier-form-field: color-mix(in srgb, var(--bg1) 82%, var(--bg2) 18%);
      --background-modifier-form-field-highlighted: var(--bg1);
      --background-modifier-box-shadow: color-mix(in srgb, black 32%, transparent);
      --background-modifier-success: color-mix(in srgb, var(--color-green) 34%, var(--bg1));
      --background-modifier-error: color-mix(in srgb, var(--color-red) 34%, var(--bg1));
      --background-modifier-error-hover: color-mix(in srgb, var(--color-red) 48%, var(--bg1));
      --background-modifier-cover: color-mix(in srgb, black 55%, transparent);

      --divider-color: var(--ui1);
      --tab-outline-color: var(--ui1);
      --ribbon-background: var(--bg2);
      --titlebar-background: var(--bg2);
      --titlebar-background-focused: var(--bg2);
      --tab-container-background: var(--bg2);
      --mobile-sidebar-background: var(--bg2);
      --workspace-background-translucent: color-mix(in srgb, var(--bg2) 72%, transparent);

      /*
        Text and selection.
      */

      --text-normal: var(--tx1);
      --text-muted: var(--tx2);
      --text-faint: var(--tx3);
      --text-accent: var(--ax1);
      --text-accent-hover: var(--ax2);
      --text-on-accent: var(--sp1);
      --text-on-accent-inverted: var(--tx1);
      --text-error: var(--color-red);
      --text-error-hover: color-mix(in srgb, var(--color-red) 82%, var(--tx1) 18%);
      --text-warning: var(--color-yellow);
      --text-success: var(--color-green);
      --text-selection: var(--hl1);
      --text-highlight-bg: var(--hl2);
      --text-highlight-bg-active: color-mix(in srgb, var(--color-yellow) 34%, transparent);
      --text-bold: var(--tx1);
      --text-italic: var(--tx1);

      /*
        Accent and interactive states.
      */

      --color-accent: var(--ax1);
      --color-accent-1: var(--ax1);
      --color-accent-2: var(--ax2);

      --interactive-normal: var(--bg1);
      --interactive-hover: color-mix(in srgb, var(--bg1) 76%, var(--ui1) 24%);
      --interactive-accent: var(--ax1);
      --interactive-accent-hover: var(--ax2);
      --interactive-success: var(--color-green);

      --icon-color: var(--tx2);
      --icon-color-hover: var(--tx1);
      --icon-color-active: var(--ax1);
      --icon-color-focused: var(--tx1);

      /*
        Links and headings.
      */

      --link-color: var(--ax1);
      --link-color-hover: var(--ax2);
      --link-decoration: none;
      --link-decoration-hover: underline;
      --link-external-color: var(--ax3);
      --link-external-color-hover: var(--ax2);
      --link-external-decoration: none;
      --link-external-decoration-hover: underline;
      --link-unresolved-color: var(--ax2);
      --link-unresolved-opacity: 0.82;

      --inline-title-color: var(--tx1);
      --title-color: var(--tx1);
      --title-color-inactive: var(--tx2);
      --h1-color: var(--color-purple);
      --h2-color: var(--color-blue);
      --h3-color: var(--color-cyan);
      --h4-color: var(--color-green);
      --h5-color: var(--color-yellow);
      --h6-color: var(--color-orange);

      /*
        Code and syntax.
      */

      --code-background: color-mix(in srgb, var(--bg2) 88%, var(--bg1) 12%);
      --code-normal: var(--tx1);
      --code-comment: var(--tx3);
      --code-function: var(--color-blue);
      --code-important: var(--color-purple);
      --code-keyword: var(--color-purple);
      --code-operator: var(--color-cyan);
      --code-property: var(--color-yellow);
      --code-punctuation: var(--tx2);
      --code-string: var(--color-green);
      --code-tag: var(--color-red);
      --code-value: var(--color-orange);

      /*
        Quotes, tables, tags, and checks.
      */

      --blockquote-border-color: var(--ax1);
      --blockquote-background-color: color-mix(in srgb, var(--ax1) 8%, var(--bg1));

      --table-border-color: var(--ui1);
      --table-header-background: color-mix(in srgb, var(--bg2) 84%, var(--ui1) 16%);
      --table-row-background-hover: color-mix(in srgb, var(--ax1) 7%, transparent);

      --tag-color: color-mix(in srgb, var(--ax1) 78%, var(--tx1) 22%);
      --tag-background: color-mix(in srgb, var(--ax1) 13%, transparent);
      --tag-background-hover: color-mix(in srgb, var(--ax1) 20%, transparent);
      --tag-border-color: color-mix(in srgb, var(--ax1) 22%, transparent);
      --tag-border-color-hover: color-mix(in srgb, var(--ax1) 34%, transparent);

      --checkbox-color: var(--ax1);
      --checkbox-color-hover: var(--ax2);
      --checkbox-marker-color: var(--sp1);
      --checkbox-border-color: var(--ui3);
      --checkbox-border-color-hover: var(--ax1);

      /*
        Navigation and tabs.
      */

      --tab-text-color: var(--tx3);
      --tab-text-color-focused: var(--tx2);
      --tab-text-color-focused-active: var(--tx1);
      --tab-text-color-focused-active-current: var(--tx1);
      --minimal-tab-text-color: var(--tx2);
      --minimal-tab-text-color-active: var(--tx1);

      --nav-item-color: var(--tx2);
      --nav-item-color-hover: var(--tx1);
      --nav-item-color-active: var(--tx1);
      --nav-item-color-selected: var(--tx1);
      --nav-item-background-hover: color-mix(in srgb, var(--ax1) 8%, transparent);
      --nav-item-background-active: color-mix(in srgb, var(--ax1) 14%, transparent);
      --nav-item-color-highlighted: var(--ax1);
      --nav-collapse-icon-color: var(--tx3);
      --nav-collapse-icon-color-collapsed: var(--tx3);
      --vault-profile-color: var(--tx2);
      --vault-profile-color-hover: var(--tx1);

      /*
        Properties, menus, modals, and graph.
      */

      --metadata-label-text-color: var(--tx3);
      --metadata-label-text-color-hover: var(--tx2);
      --metadata-input-text-color: var(--tx2);
      --metadata-input-text-color-hover: var(--tx1);
      --metadata-property-background: transparent;
      --metadata-property-background-hover: color-mix(in srgb, var(--ax1) 6%, transparent);
      --metadata-divider-color: var(--ui1);

      --modal-background: var(--bg1);
      --modal-border-color: var(--ui1);
      --prompt-border-color: var(--ui1);
      --background-modifier-message: var(--bg2);
      --menu-background: var(--bg2);
      --menu-border-color: var(--ui1);
      --menu-separator-color: var(--ui1);

      --graph-line: var(--ui1);
      --graph-node: var(--color-blue);
      --graph-node-unresolved: var(--color-red);
      --graph-node-focused: var(--color-purple);
      --graph-node-tag: var(--color-green);
      --graph-node-attachment: var(--color-yellow);

      --scrollbar-bg: transparent;
      --scrollbar-thumb-bg: color-mix(in srgb, var(--ui2) 72%, transparent);
      --scrollbar-active-thumb-bg: color-mix(in srgb, var(--ui3) 88%, transparent);
    }
  ''
