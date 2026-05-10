{
  pkgs,
  source,
  colors,
  fontFamily,
}: let
  cacheInputs = {
    inherit fontFamily;
    base00 = colors.base00;
    base05 = colors.base05;
    base0A = colors.base0A;
    base0D = colors.base0D;
    base0E = colors.base0E;
  };
  cacheKey = builtins.substring 0 12 (
    builtins.hashString "sha256" (builtins.toJSON cacheInputs)
  );

  startpageCss = pkgs.writeText "startpage-style.css" ''
    :root {
      --color-bg: #${colors.base00};
      --color-fg: #${colors.base05};
      --color-link: #${colors.base0D};
      --color-link-visited: #${colors.base0E};
      --color-link-hover: #${colors.base0A};
    }

    html, body {
      background: var(--color-bg);
      color: var(--color-fg);
      font-family: "${fontFamily}";
      height: 100%;
      width: 100%;
      margin: 0;
      padding: 0;
    }

    .container {
      display: grid;
      grid-template-columns: 1fr 460px 600px 1fr;
      grid-template-areas:
        ". left right .";
      column-gap: 80px;
      justify-items: center;
      align-items: center;
      min-height: 100%;
    }

    .left-container {
      grid-area: left;
      aspect-ratio: 1/1;
    }

    .right-container {
      grid-area: right;
      height: 50%;
      width: 100%;
    }

    .gif img {
      max-width: 100%;
      max-height: 100%;
      width: 350px;
      height: auto;
    }

    .head {
      display: flex;
      flex-direction: column;
      align-items: center;
      font-size: 40px;
      padding-top: 60px;
    }

    .category {
      display: flex;
      flex-direction: column;
      width: 180px;
    }

    .bookmarks {
      display: flex;
      justify-content: center;
    }

    .links {
      display: flex;
      white-space: nowrap;
      flex-direction: column;
      align-items: center;
      padding-top: 20px;
      padding-bottom: 20px;
    }

    .title {
      font-size: 20px;
    }

    li {
      font-size: 16px;
      list-style-type: none;
      padding: 5px;
    }

    a:link {
      text-decoration: none;
      color: var(--color-link);
    }

    a:visited {
      color: var(--color-link-visited);
    }

    a:hover {
      color: var(--color-link-hover);
    }

    @keyframes opacity {
      0% {
        opacity: 1;
      }

      50% {
        opacity: 0;
      }

      100% {
        opacity: 1;
      }
    }
  '';
in
  pkgs.runCommand "stylix-startpage" {} ''
    mkdir -p "$out"
    sed 's#href="style.css"#href="style.css?v=${cacheKey}"#g' ${source}/index.html > "$out/index.html"
    cp ${source}/totoro.gif "$out/totoro.gif"
    cp ${source}/cat.gif "$out/cat.gif"
    cp ${startpageCss} "$out/style.css"
  ''
