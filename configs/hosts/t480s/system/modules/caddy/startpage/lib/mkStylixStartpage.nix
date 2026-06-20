{
  pkgs,
  source,
  colors,
  fontFamily,
  sansFontFamily ? fontFamily,
}: let
  color = name: "#${builtins.getAttr name colors}";
  cssFontFamily = builtins.toJSON sansFontFamily;
  cssMonoFontFamily = builtins.toJSON fontFamily;

  cacheInputs = {
    inherit fontFamily sansFontFamily;
    base00 = colors.base00;
    base01 = colors.base01;
    base02 = colors.base02;
    base03 = colors.base03;
    base05 = colors.base05;
    base08 = colors.base08;
    base0A = colors.base0A;
    base0B = colors.base0B;
    base0C = colors.base0C;
    base0D = colors.base0D;
    base0E = colors.base0E;
  };
  cacheKey = builtins.substring 0 12 (
    builtins.hashString "sha256" (builtins.toJSON cacheInputs)
  );

  baseCss = builtins.readFile (source + "/style.css");
  stylixBackground = color "base00";

  baseCssStyle = pkgs.writeText "startpage-base-css.html" ''
    <style id="startpage-base-css">
    ${baseCss}
    </style>
    <link rel="stylesheet" href="stylix.css?v=${cacheKey}" />
  '';

  stylixCss = pkgs.writeText "startpage-stylix.css" ''
    html.stylix-mode body {
      --background-color: ${color "base00"};
      --text-color: ${color "base05"};
      --card-background: color-mix(in srgb, ${color "base01"} 78%, transparent);
      --card-border: color-mix(in srgb, ${color "base03"} 62%, transparent);
      --terminal-bg: color-mix(in srgb, ${color "base01"} 88%, transparent);
      --terminal-text: ${color "base05"};
      --shadow-color: color-mix(in srgb, ${color "base00"} 70%, transparent);
      --link-background: color-mix(in srgb, ${color "base02"} 72%, transparent);
      --link-hover: color-mix(in srgb, ${color "base03"} 64%, transparent);
      --color-primary: ${color "base0D"};
      --color-warning: ${color "base0A"};
      --color-error: ${color "base08"};
      --color-success: ${color "base0B"};
      --color-version: ${color "base0B"};
      --font-family: "Inter", ${cssFontFamily}, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
      --monospace-font-family: "Source Code Pro", ${cssMonoFontFamily}, ui-monospace, "Cascadia Code", "Fira Code", "Fira Mono", "Consolas", "Menlo", monospace;
      color-scheme: dark;
    }

    html.stylix-mode body {
      background: var(--background-color);
    }

    html.stylix-mode #theme-overlay-scanlines,
    html.stylix-mode #theme-overlay-texture {
      display: none;
    }

    html.stylix-mode .bookmark-icon {
      filter: none;
    }
  '';

  localDefaultsJs = pkgs.writeText "startpage-local-defaults.js" ''
    (function () {
      window.STARTPAGE_STYLIX_BACKGROUND = "${stylixBackground}";
      window.STARTPAGE_DEFAULT_SYNTAX_COLORS = {
        cmd: "${color "base0D"}",
        theme: "${color "base0E"}",
        search: "${color "base0A"}",
        version: "${color "base0B"}",
        url: "${color "base0C"}",
        unknown: "${color "base08"}"
      };

      const meta = document.getElementById("meta-theme-color");
      if (meta) meta.setAttribute("content", window.STARTPAGE_STYLIX_BACKGROUND);

      if (!localStorage.getItem("syntaxColors") && typeof applySyntaxColors === "function") {
        applySyntaxColors(window.STARTPAGE_DEFAULT_SYNTAX_COLORS);
      }
    })();
  '';

in
  pkgs.runCommand "stylix-terminal-startpage" {nativeBuildInputs = [pkgs.gawk];} ''
    mkdir -p "$out"

    cp ${source}/style.css "$out/style.css"
    cp -R ${source}/icon "$out/icon"
    cp -R ${source}/script "$out/script"
    cp -R ${source}/version "$out/version"
    chmod -R u+w "$out/script"

    mkdir -p "$out/focus"
    cp ${source}/focus/focus.html "$out/focus/focus.html"
    sed 's|__STYLIX_BACKGROUND__|${stylixBackground}|g' \
      ${source}/focus/focus.js > "$out/focus/focus.js"

    awk -v base_css_style="${baseCssStyle}" '
      /<link rel="stylesheet" href="style[.]css"/ {
        while ((getline line < base_css_style) > 0) {
          print line
        }
        close(base_css_style)
        next
      }
      { print }
    ' ${source}/index.html | sed \
      -e 's#<script src="script/storage.js"></script>#<script src="script/storage.js"></script>\
  <script src="script/local-defaults.js?v=${cacheKey}"></script>#' \
      > "$out/index.html"

    cp ${stylixCss} "$out/stylix.css"
    cp ${localDefaultsJs} "$out/script/local-defaults.js"
  ''
