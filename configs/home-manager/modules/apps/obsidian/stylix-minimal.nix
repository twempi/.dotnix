{
  pkgs,
  config,
  ...
}: let
  colors = config.lib.stylix.colors.withHashtag;
in
  pkgs.writeText "stylix-minimal.css" ''
    /*
      Stylix x Minimal — cohesive Everforest-style palette

      This only writes CSS variables and cosmetic overrides.
      It does not select, enable, or modify the active Obsidian theme.
    */

    body.theme-dark,
    body.theme-light {
      /*
        Stylix palette aliases.
        These are deliberately remixed instead of mapped 1:1 so the UI feels
        closer to Minimal's Everforest preset: softer panels, green/cyan accent,
        and lower-contrast borders.
      */

      --stylix-bg: ${colors.base00};
      --stylix-bg-alt: ${colors.base01};
      --stylix-surface: ${colors.base02};
      --stylix-border: ${colors.base03};
      --stylix-muted: ${colors.base04};
      --stylix-fg: ${colors.base05};

      --stylix-red: ${colors.base08};
      --stylix-orange: ${colors.base09};
      --stylix-yellow: ${colors.base0A};
      --stylix-green: ${colors.base0B};
      --stylix-cyan: ${colors.base0C};
      --stylix-blue: ${colors.base0D};
      --stylix-purple: ${colors.base0E};
      --stylix-pink: ${colors.base0F};

      /*
        Minimal color names.
        Keep Everforest's feel by making green/cyan the primary UI accent,
        while preserving the full Base16 palette for syntax and headings.
      */

      --color-red: var(--stylix-red);
      --color-orange: var(--stylix-orange);
      --color-yellow: var(--stylix-yellow);
      --color-green: var(--stylix-green);
      --color-cyan: var(--stylix-cyan);
      --color-blue: var(--stylix-blue);
      --color-purple: var(--stylix-purple);
      --color-pink: var(--stylix-pink);

      /*
        Minimal core system.
        These are the variables that make the preset Minimal schemes feel cohesive.
      */

      --bg1: var(--stylix-bg);
      --bg2: color-mix(in srgb, var(--stylix-bg-alt) 86%, var(--stylix-cyan) 14%);
      --bg3: color-mix(in srgb, var(--stylix-surface) 48%, transparent);

      --ui1: color-mix(in srgb, var(--stylix-surface) 82%, var(--stylix-cyan) 18%);
      --ui2: color-mix(in srgb, var(--stylix-border) 78%, var(--stylix-green) 22%);
      --ui3: color-mix(in srgb, var(--stylix-muted) 70%, var(--stylix-green) 30%);

      --tx1: var(--stylix-fg);
      --tx2: color-mix(in srgb, var(--stylix-fg) 68%, var(--stylix-muted) 32%);
      --tx3: color-mix(in srgb, var(--stylix-muted) 72%, var(--stylix-bg) 28%);
      --tx4: var(--stylix-yellow);

      --ax1: var(--stylix-green);
      --ax2: var(--stylix-cyan);
      --ax3: var(--stylix-yellow);

      --hl1: color-mix(in srgb, var(--stylix-green) 24%, transparent);
      --hl2: color-mix(in srgb, var(--stylix-yellow) 20%, transparent);
      --hl3: color-mix(in srgb, var(--stylix-purple) 18%, transparent);

      /*
        Minimal/Obsidian HSL anchors.
        These help derived colors stay coherent instead of falling back to stock.
      */

      --base-h: 203;
      --base-s: 15%;
      --base-l: 23%;

      --accent-h: 81;
      --accent-s: 34%;
      --accent-l: 63%;

      /*
        Obsidian base ramp.
      */

      --color-base-00: color-mix(in srgb, var(--bg1) 94%, black 6%);
      --color-base-05: color-mix(in srgb, var(--bg1) 96%, white 4%);
      --color-base-10: var(--bg1);
      --color-base-20: var(--bg2);
      --color-base-25: color-mix(in srgb, var(--bg2) 78%, var(--ui1) 22%);
      --color-base-30: var(--ui1);
      --color-base-35: color-mix(in srgb, var(--ui1) 72%, var(--ui2) 28%);
      --color-base-40: var(--ui2);
      --color-base-50: var(--ui3);
      --color-base-60: var(--tx3);
      --color-base-70: var(--tx2);
      --color-base-100: var(--tx1);

      /*
        App backgrounds.
      */

      --background-primary: var(--bg1);
      --background-primary-alt: color-mix(in srgb, var(--bg1) 84%, var(--bg2) 16%);
      --background-secondary: var(--bg2);
      --background-secondary-alt: color-mix(in srgb, var(--bg2) 76%, var(--bg1) 24%);

      --background-modifier-border: var(--ui1);
      --background-modifier-border-hover: var(--ui2);
      --background-modifier-border-focus: var(--ax1);
      --background-modifier-hover: var(--bg3);
      --background-modifier-active-hover: color-mix(in srgb, var(--ax1) 13%, transparent);
      --background-modifier-form-field: color-mix(in srgb, var(--bg1) 84%, var(--bg2) 16%);
      --background-modifier-form-field-highlighted: var(--bg2);
      --background-modifier-box-shadow: color-mix(in srgb, black 32%, transparent);
      --background-modifier-success: color-mix(in srgb, var(--stylix-green) 35%, var(--bg1));
      --background-modifier-error: color-mix(in srgb, var(--stylix-red) 35%, var(--bg1));
      --background-modifier-error-hover: color-mix(in srgb, var(--stylix-red) 48%, var(--bg1));

      /*
        Text.
      */

      --text-normal: var(--tx1);
      --text-muted: var(--tx2);
      --text-faint: var(--tx3);
      --text-accent: var(--ax2);
      --text-accent-hover: var(--ax1);
      --text-on-accent: var(--bg1);
      --text-error: var(--stylix-red);
      --text-error-hover: color-mix(in srgb, var(--stylix-red) 80%, white 20%);
      --text-warning: var(--stylix-yellow);
      --text-success: var(--stylix-green);
      --text-selection: color-mix(in srgb, var(--ax1) 22%, transparent);
      --text-highlight-bg: var(--hl2);
      --text-highlight-bg-active: color-mix(in srgb, var(--stylix-yellow) 32%, transparent);

      /*
        Accent and interactive elements.
      */

      --color-accent: var(--ax1);
      --color-accent-1: var(--ax1);
      --color-accent-2: var(--ax2);

      --interactive-normal: var(--bg2);
      --interactive-hover: color-mix(in srgb, var(--bg2) 74%, var(--ui1) 26%);
      --interactive-accent: var(--ax1);
      --interactive-accent-hover: var(--ax2);
      --interactive-success: var(--stylix-green);

      /*
        Links.
      */

      --link-color: var(--ax2);
      --link-color-hover: var(--ax1);
      --link-decoration: none;
      --link-decoration-hover: underline;
      --link-external-color: var(--stylix-cyan);
      --link-external-color-hover: var(--stylix-green);
      --link-external-decoration: none;
      --link-external-decoration-hover: underline;
      --link-unresolved-color: var(--stylix-purple);
      --link-unresolved-opacity: 0.85;

      /*
        Headings.
      */

      --inline-title-color: var(--stylix-purple);

      --h1-color: var(--stylix-purple);
      --h2-color: var(--stylix-blue);
      --h3-color: var(--stylix-cyan);
      --h4-color: var(--stylix-green);
      --h5-color: var(--stylix-yellow);
      --h6-color: var(--stylix-orange);

      --h1-weight: 700;
      --h2-weight: 700;
      --h3-weight: 700;
      --h4-weight: 700;
      --h5-weight: 700;
      --h6-weight: 700;

      /*
        Code and syntax.
      */

      --code-background: color-mix(in srgb, var(--bg2) 86%, var(--bg1) 14%);
      --code-normal: var(--tx1);
      --code-comment: var(--tx3);
      --code-function: var(--stylix-blue);
      --code-important: var(--stylix-purple);
      --code-keyword: var(--stylix-purple);
      --code-operator: var(--stylix-cyan);
      --code-property: var(--stylix-yellow);
      --code-punctuation: var(--tx2);
      --code-string: var(--stylix-green);
      --code-tag: var(--stylix-red);
      --code-value: var(--stylix-orange);

      /*
        Quotes, tables, tags.
      */

      --blockquote-border-color: var(--ax1);
      --blockquote-background-color: color-mix(in srgb, var(--ax1) 7%, var(--bg1));

      --table-border-color: var(--ui1);
      --table-header-background: color-mix(in srgb, var(--bg2) 82%, var(--ui1) 18%);
      --table-row-background-hover: color-mix(in srgb, var(--ax1) 7%, transparent);

      --tag-color: color-mix(in srgb, var(--ax1) 78%, var(--tx1) 22%);
      --tag-background: color-mix(in srgb, var(--ax1) 13%, transparent);
      --tag-background-hover: color-mix(in srgb, var(--ax1) 20%, transparent);
      --tag-border-color: color-mix(in srgb, var(--ax1) 22%, transparent);
      --tag-border-color-hover: color-mix(in srgb, var(--ax1) 34%, transparent);

      /*
        Checkboxes.
      */

      --checkbox-color: var(--ax1);
      --checkbox-color-hover: var(--ax2);
      --checkbox-marker-color: var(--bg1);
      --checkbox-border-color: var(--ui3);
      --checkbox-border-color-hover: var(--ax1);

      /*
        Navigation, tabs, sidebars.
      */

      --titlebar-background: var(--bg2);
      --titlebar-background-focused: var(--bg2);

      --ribbon-background: var(--bg2);
      --ribbon-background-collapsed: var(--bg2);

      --tab-container-background: var(--bg2);
      --tab-outline-color: var(--ui1);
      --tab-text-color: var(--tx3);
      --tab-text-color-focused: var(--tx2);
      --tab-text-color-focused-active: var(--tx1);
      --tab-text-color-focused-active-current: var(--tx1);

      --nav-item-color: var(--tx2);
      --nav-item-color-hover: var(--tx1);
      --nav-item-color-active: var(--tx1);
      --nav-item-background-hover: color-mix(in srgb, var(--ax1) 8%, transparent);
      --nav-item-background-active: color-mix(in srgb, var(--ax1) 14%, transparent);
      --nav-item-color-highlighted: var(--ax1);

      --nav-collapse-icon-color: var(--tx3);
      --nav-collapse-icon-color-collapsed: var(--tx3);

      --vault-profile-color: var(--tx2);
      --vault-profile-color-hover: var(--tx1);

      /*
        Properties / metadata.
      */

      --metadata-label-text-color: var(--tx3);
      --metadata-label-text-color-hover: var(--tx2);
      --metadata-input-text-color: var(--tx2);
      --metadata-input-text-color-hover: var(--tx1);
      --metadata-property-background: transparent;
      --metadata-property-background-hover: color-mix(in srgb, var(--ax1) 6%, transparent);
      --metadata-divider-color: var(--ui1);

      /*
        Prompts, modals, menus.
      */

      --modal-background: var(--bg1);
      --modal-border-color: var(--ui1);
      --prompt-border-color: var(--ui1);
      --background-modifier-message: var(--bg2);

      --menu-background: var(--bg2);
      --menu-border-color: var(--ui1);
      --menu-separator-color: var(--ui1);

      /*
        Scrollbars.
      */

      --scrollbar-bg: transparent;
      --scrollbar-thumb-bg: color-mix(in srgb, var(--ui2) 72%, transparent);
      --scrollbar-active-thumb-bg: color-mix(in srgb, var(--ui3) 88%, transparent);

      /*
        Graph view.
      */

      --graph-line: var(--ui1);
      --graph-node: var(--stylix-blue);
      --graph-node-unresolved: var(--stylix-red);
      --graph-node-focused: var(--stylix-purple);
      --graph-node-tag: var(--stylix-green);
      --graph-node-attachment: var(--stylix-yellow);

      /*
        Shape and density.
      */

      --radius-s: 5px;
      --radius-m: 8px;
      --radius-l: 12px;
      --input-radius: 6px;
      --tab-radius-active: 8px 8px 0 0;
    }

    /*
      Slightly warmer dark-mode surfaces.
    */

    body.theme-dark {
      --bg1: var(--stylix-bg);
      --bg2: color-mix(in srgb, var(--stylix-bg-alt) 84%, var(--stylix-cyan) 16%);
      --bg3: color-mix(in srgb, var(--stylix-surface) 42%, transparent);

      --ui1: color-mix(in srgb, var(--stylix-surface) 72%, var(--stylix-cyan) 28%);
      --ui2: color-mix(in srgb, var(--stylix-border) 72%, var(--stylix-green) 28%);
      --ui3: color-mix(in srgb, var(--stylix-muted) 74%, var(--stylix-green) 26%);

      --tx1: var(--stylix-fg);
      --tx2: color-mix(in srgb, var(--stylix-fg) 66%, var(--stylix-muted) 34%);
      --tx3: color-mix(in srgb, var(--stylix-muted) 72%, var(--stylix-bg) 28%);
    }

    /*
      Light mode is included so the snippet does not become unusable if you
      temporarily switch Obsidian to light mode.
    */

    body.theme-light {
      --base-h: 44;
      --base-s: 87%;
      --base-l: 94%;

      --accent-h: 83;
      --accent-s: 36%;
      --accent-l: 53%;

      --bg1: var(--stylix-bg);
      --bg2: color-mix(in srgb, var(--stylix-bg-alt) 88%, var(--stylix-yellow) 12%);
      --bg3: color-mix(in srgb, var(--stylix-surface) 38%, transparent);

      --ui1: color-mix(in srgb, var(--stylix-surface) 74%, var(--stylix-green) 26%);
      --ui2: color-mix(in srgb, var(--stylix-border) 72%, var(--stylix-green) 28%);
      --ui3: color-mix(in srgb, var(--stylix-muted) 78%, var(--stylix-green) 22%);
    }

    /*
      Cohesive app chrome.
    */

    body.theme-dark .workspace,
    body.theme-light .workspace {
      background-color: var(--bg1);
    }

    body.theme-dark .titlebar,
    body.theme-light .titlebar,
    body.theme-dark .workspace-ribbon,
    body.theme-light .workspace-ribbon,
    body.theme-dark .mod-left-split,
    body.theme-light .mod-left-split,
    body.theme-dark .mod-right-split,
    body.theme-light .mod-right-split,
    body.theme-dark .workspace-tabs.mod-top .workspace-tab-header-container,
    body.theme-light .workspace-tabs.mod-top .workspace-tab-header-container,
    body.theme-dark .status-bar,
    body.theme-light .status-bar {
      background-color: var(--bg2);
      border-color: var(--ui1);
    }

    body.theme-dark .workspace-leaf,
    body.theme-light .workspace-leaf,
    body.theme-dark .workspace-leaf-content,
    body.theme-light .workspace-leaf-content {
      background-color: var(--bg1);
    }

    body.theme-dark .workspace-tab-header,
    body.theme-light .workspace-tab-header {
      color: var(--tx3);
    }

    body.theme-dark .workspace-tab-header.is-active,
    body.theme-light .workspace-tab-header.is-active {
      background-color: var(--bg1);
      color: var(--tx1);
      box-shadow: inset 0 -2px 0 var(--ax1);
    }

    body.theme-dark .workspace-tab-header:hover,
    body.theme-light .workspace-tab-header:hover {
      background-color: color-mix(in srgb, var(--ax1) 7%, transparent);
      color: var(--tx1);
    }

    body.theme-dark .nav-file-title:hover,
    body.theme-light .nav-file-title:hover,
    body.theme-dark .nav-folder-title:hover,
    body.theme-light .nav-folder-title:hover,
    body.theme-dark .tree-item-self:hover,
    body.theme-light .tree-item-self:hover {
      background-color: var(--nav-item-background-hover);
      color: var(--nav-item-color-hover);
    }

    body.theme-dark .nav-file-title.is-active,
    body.theme-light .nav-file-title.is-active,
    body.theme-dark .tree-item-self.is-active,
    body.theme-light .tree-item-self.is-active {
      background-color: var(--nav-item-background-active);
      color: var(--nav-item-color-active);
    }

    /*
      Editor/readable content polish.
    */

    body.theme-dark .markdown-source-view,
    body.theme-light .markdown-source-view,
    body.theme-dark .markdown-preview-view,
    body.theme-light .markdown-preview-view {
      color: var(--tx1);
    }

    body.theme-dark .cm-active,
    body.theme-light .cm-active {
      background-color: color-mix(in srgb, var(--ax1) 5%, transparent);
    }

    body.theme-dark .cm-selectionBackground,
    body.theme-light .cm-selectionBackground,
    body.theme-dark ::selection,
    body.theme-light ::selection {
      background-color: var(--text-selection);
    }

    body.theme-dark hr,
    body.theme-light hr {
      border-color: var(--ui1);
    }

    body.theme-dark .markdown-rendered blockquote,
    body.theme-light .markdown-rendered blockquote {
      background-color: var(--blockquote-background-color);
      border-color: var(--blockquote-border-color);
    }

    body.theme-dark .markdown-rendered code,
    body.theme-light .markdown-rendered code,
    body.theme-dark .cm-inline-code,
    body.theme-light .cm-inline-code {
      background-color: color-mix(in srgb, var(--code-background) 84%, var(--ax1) 6%);
      color: var(--code-normal);
      border: 1px solid color-mix(in srgb, var(--ui1) 72%, transparent);
    }

    body.theme-dark .markdown-rendered pre,
    body.theme-light .markdown-rendered pre,
    body.theme-dark .HyperMD-codeblock,
    body.theme-light .HyperMD-codeblock {
      background-color: var(--code-background);
    }

    /*
      Callouts: keep their native callout color, but blend it into the theme.
    */

    body.theme-dark .callout,
    body.theme-light .callout {
      background-color: color-mix(in srgb, rgb(var(--callout-color)) 9%, var(--bg1));
      border-color: color-mix(in srgb, rgb(var(--callout-color)) 30%, var(--ui1));
    }

    body.theme-dark .callout-title,
    body.theme-light .callout-title {
      color: color-mix(in srgb, rgb(var(--callout-color)) 70%, var(--tx1));
    }

    /*
      Properties.
    */

    body.theme-dark .metadata-container,
    body.theme-light .metadata-container {
      color: var(--tx2);
    }

    body.theme-dark .metadata-property:hover,
    body.theme-light .metadata-property:hover {
      background-color: var(--metadata-property-background-hover);
    }

    body.theme-dark .metadata-property-key,
    body.theme-light .metadata-property-key {
      color: var(--metadata-label-text-color);
    }

    body.theme-dark .metadata-property-value,
    body.theme-light .metadata-property-value {
      color: var(--metadata-input-text-color);
    }

    /*
      Tags.
    */

    body.theme-dark .tag,
    body.theme-light .tag,
    body.theme-dark .multi-select-pill,
    body.theme-light .multi-select-pill {
      color: var(--tag-color);
      background-color: var(--tag-background);
      border: 1px solid var(--tag-border-color);
    }

    body.theme-dark .tag:hover,
    body.theme-light .tag:hover,
    body.theme-dark .multi-select-pill:hover,
    body.theme-light .multi-select-pill:hover {
      background-color: var(--tag-background-hover);
      border-color: var(--tag-border-color-hover);
    }

    /*
      Tables.
    */

    body.theme-dark table,
    body.theme-light table {
      border-color: var(--table-border-color);
    }

    body.theme-dark thead,
    body.theme-light thead {
      background-color: var(--table-header-background);
    }

    body.theme-dark tbody tr:hover,
    body.theme-light tbody tr:hover {
      background-color: var(--table-row-background-hover);
    }

    /*
      Dataview empty text and inline fields.
    */

    body.theme-dark .dataview.result-group,
    body.theme-light .dataview.result-group,
    body.theme-dark .dataview-error,
    body.theme-light .dataview-error {
      color: var(--tx3);
    }

    body.theme-dark .dataview.inline-field-key,
    body.theme-light .dataview.inline-field-key,
    body.theme-dark .dataview.inline-field-value,
    body.theme-light .dataview.inline-field-value,
    body.theme-dark .dataview .inline-field-standalone-value,
    body.theme-light .dataview .inline-field-standalone-value {
      background-color: color-mix(in srgb, var(--bg2) 70%, transparent);
      color: var(--tx2);
    }
  ''
