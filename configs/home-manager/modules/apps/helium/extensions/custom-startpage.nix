{
  config,
  homePageOrigin,
  pkgs,
}: let
  startpageSource = ../../../../../hosts/t480s/system/modules/caddy/startpage;
  mkStylixStartpage =
    import ../../../../../hosts/t480s/system/modules/caddy/startpage/lib/mkStylixStartpage.nix;
  startpageSite = mkStylixStartpage {
    inherit pkgs;
    source = startpageSource;
    colors = config.lib.stylix.colors;
    fontFamily = config.stylix.fonts.monospace.name;
    sansFontFamily = config.stylix.fonts.sansSerif.name;
  };
in
  pkgs.runCommand "helium-startpage-extension" {nativeBuildInputs = [pkgs.jq];} ''
    mkdir -p "$out"

    cp -R ${startpageSite}/. "$out/"
    chmod -R u+w "$out"

    cat > "$out/script/extension-env.js" <<'EOF'
    window.STARTPAGE_SETTINGS_URL = ${builtins.toJSON "${homePageOrigin}/settings.json"};
    window.STARTPAGE_SETTINGS_API_URL = ${builtins.toJSON "${homePageOrigin}/api/settings"};
    window.STARTPAGE_USE_LOCAL_SETTINGS_CACHE = true;
    EOF

    substituteInPlace "$out/index.html" \
      --replace-fail '<script src="script/storage.js"></script>' \
        '<script src="script/extension-env.js"></script>
      <script src="script/storage.js"></script>'

    jq \
      --arg origin ${builtins.toJSON homePageOrigin} \
      --arg host ${builtins.toJSON "${homePageOrigin}/*"} \
      '
        .chrome_url_overrides.newtab = "focus/focus.html"
        | .host_permissions = (((.host_permissions // []) + [$host]) | unique)
        | .content_security_policy.extension_pages |= (
            if contains($origin) then . else sub("connect-src "; "connect-src \($origin) ") end
          )
      ' ${startpageSource}/manifests/chrome.json > "$out/manifest.json"
  ''
