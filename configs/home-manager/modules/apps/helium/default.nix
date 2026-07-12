{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  homePageOrigin = "https://t480s.tailae03d0.ts.net";
  homePage = "${homePageOrigin}/";
  startpageSource = ../../../../hosts/t480s/system/modules/caddy/startpage;
  mkStylixStartpage = import ../../../../hosts/t480s/system/modules/caddy/startpage/lib/mkStylixStartpage.nix;
  startpageSite = mkStylixStartpage {
    inherit pkgs;
    source = startpageSource;
    colors = config.lib.stylix.colors;
    fontFamily = config.stylix.fonts.monospace.name;
    sansFontFamily = config.stylix.fonts.sansSerif.name;
  };

  heliumProfileDir = "Profile";

  webStoreExtensions = [
    {
      # AI Grammar Checker & Paraphraser - LanguageTool
      id = "oldceeleldhonbafppcapldpdifcinji";
      hash = "sha256-UEVCv/S2Clfzp9mU6c8q/NjAqug5GU4EZnu5z8l/LJE=";
    }
    {
      # File Icons for GitHub and GitLab
      id = "ficfmibkjjnpogdcfhfokmihanoldbfe";
      hash = "sha256-r9RsPoGXx/dka1INM9KOddNl6ccHCjHHEqJmcjsUPYM=";
    }
    {
      # SponsorBlock for YouTube
      id = "mnjggcdmjocbbbhaepdhchncahnbgone";
      hash = "sha256-nE5FE3Eo1jG8sT1KYjVl8JRbmAiyhN8IZObHsAIb0wY=";
    }
    {
      # Return YouTube Dislike
      id = "gebbhagfogifgggkldgodflihgfeippi";
      hash = "sha256-0ZO+7AY5dcy1AOXPtZ9sSPcj9Wl2RQkE9oOFZq7ESqM=";
    }
    {
      # ClearURLs
      id = "lckanjgmijmafbedllaakclkaicjfmnk";
      hash = "sha256-rMFzGyrQCJ85p93PDHIy7TU329AZuOjBvuzoeO1Yoxo=";
    }
    {
      # Improve YouTube
      id = "bnomihfieiccainjcjblhegjgglakjdd";
      hash = "sha256-xFEBWKB0ZPQ3myFJw9+RK2ohVloHvpA+acL1VK5fUJs=";
    }
    {
      # Vimium
      id = "dbepggeogbaibhgnhhndojpepiihcmeb";
      hash = "sha256-MZjCaqcZvkYt6lhQUPvtm4uAYo1X6oihE7q/UzTFUXw=";
    }
    {
      # Bitwarden Password Manager
      id = "nngceckbapebfimnlniiiahkandclblb";
      hash = "sha256-XOVs2Tvay8hQ13SHz+728BDu2mMyQ0JxUuUI6FZ1NaM=";
    }
    {
      # Floccus Bookmarks Sync
      id = "fnaicdffflnofjppbagibeoednhnbjhg";
      hash = "sha256-+/cyGI5sj6V9OitbBeOl/pkM//Vj/qACXpgkn8TETz0=";
    }
    {
      # Imagus Reborn
      id = "fcjmgeodgobggcppooncdagfkogfffdm";
      hash = "sha256-ioqkGne9PJUqoNV//PIfQlG3CIfGzhsXpJmS5Pt5bCM=";
    }
    {
      # Better Campus
      id = "cndibmoanboadcifjkjbdpjgfedanolh";
      hash = "sha256-sJi02k5DgLpwrsrQHqlvXdWu4tNW+WqFiMT0qbsmXvc=";
    }
    # Video DownloadHelper
    {
      id = "lmjnegcaeklhafolokijcfjliaokphfk";
      hash = "sha256-7nJNCJ4qvjzuUIgljdaPo7UnQZf9YNCyy2xBmq87e/w=";
    }
    # ChatGPT Exporter
    {
      id = "ilmdofdhpnhffldihboadndccenlnfll";
      hash = "sha256-InqXKKEblfVEehgnEjFYCjrzVnbr90djmzyROKH/NCA=";
    }
    # Polyratings Extension
    {
      id = "eboaimjcbpkmciikmjpceacdacegnfao";
      hash = "sha256-xXPE57buWkwYAG+V0K6LbErYQh8XoZUOYSrOCGzNndY=";
    }
    # Obsidian Web Clipper
    {
      id = "cnjifjpddelmedmihgijeibhnjfabmlf";
      hash = "sha256-4BLH0QvZj3yL4tqv/WBdZKij1Vye4p26oy4b9oB25/M=";
    }

    {
      id = "bgpnjdahpmkaflfpbkdplndklnmghklp";
      hash = "sha256-L4ts/TG52HaHah9ZZBnVKjT6+h8tUY9C/eYeZcx6cMM=";
    }
  ];

  fetchExtension = {
    id,
    hash,
  }: let
    os =
      if pkgs.stdenv.isDarwin
      then "mac"
      else "linux";
    arch =
      if pkgs.stdenv.isAarch64
      then "arm64"
      else "x64";
    os_arch =
      if pkgs.stdenv.isDarwin
      then "arm64"
      else "x86_64";
  in
    pkgs.fetchurl {
      name = "${id}.crx";
      url = "https://clients2.google.com/service/update2/crx?response=redirect&os=${os}&arch=${arch}&os_arch=${os_arch}&nacl_arch=x86-64&prod=chromiumcrx&prodchannel=stable&prodversion=120.0.0.0&acceptformat=crx3&x=id%3D${id}%26installsource%3Dondemand%26uc";
      inherit hash;
    };

  externalExtensionJson = {
    id,
    hash,
  }:
    pkgs.runCommand "helium-external-extension-${id}.json" {
      nativeBuildInputs = [pkgs.jq pkgs.unzip];
      crx = fetchExtension {inherit id hash;};
    } ''
      manifest="$(unzip -p "$crx" manifest.json 2>/dev/null || true)"
      version="$(printf '%s' "$manifest" | jq -r .version)"
      test -n "$version"
      test "$version" != "null"

      jq -n \
        --arg crx "$crx" \
        --arg version "$version" \
        '{ external_crx: $crx, external_version: $version }' > "$out"
    '';

  localNewTabExtension = pkgs.runCommand "helium-startpage-extension" {nativeBuildInputs = [pkgs.jq];} ''
    mkdir -p "$out"

    cp -R ${startpageSite}/. "$out/"
    chmod -R u+w "$out"

    cat > "$out/script/extension-env.js" <<'EOF'
    window.STARTPAGE_SETTINGS_URL = ${builtins.toJSON "${homePageOrigin}/settings.json"};
    window.STARTPAGE_SETTINGS_API_URL = ${builtins.toJSON "${homePageOrigin}/api/settings"};
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
  '';

  allUnpackedExtensionPaths = map toString [localNewTabExtension];

  profilePreferences = {
    browser = {
      show_home_button = false;
    };

    bookmark_bar = {
      show_apps_shortcut = false;
      show_managed_bookmarks = true;
      show_on_all_tabs = true;
      show_tab_groups = false;
    };

    homepage = homePage;
    homepage_is_newtabpage = false;

    session = {
      restore_on_startup = 5;
      startup_urls = [];
    };

    vertical_tabs = {
      collapsed_state = true;
      enabled = true;
      uncollapsed_width = 200;
    };

    autofill = {
      credit_card_enabled = false;
      profile_enabled = false;
    };

    credentials_enable_service = true;

    profile = {
      password_manager_enabled = false;
    };
  };
in {
  imports = [inputs.helium.homeModules.helium];

  programs.helium = {
    enable = true;
    defaultBrowser = true;
    package = inputs.helium-package.packages.${pkgs.stdenv.hostPlatform.system}.helium;

    extensions = [];

    extraFlags = [
      "--profile-directory=${heliumProfileDir}"
      "--force-dark-mode"
      "--load-extension=${lib.concatStringsSep "," allUnpackedExtensionPaths}"
    ];

    extraPolicies = {
      AutofillAddressEnabled = true;
      AutofillCreditCardEnabled = false;
      BackgroundModeEnabled = false;
      BlockThirdPartyCookies = true;
      BookmarkBarEnabled = true;
      BrowserSignin = 0;
      DefaultBrowserSettingEnabled = false;
      DefaultSearchProviderEnabled = true;
      DefaultSearchProviderName = "Brave Search";
      DefaultSearchProviderKeyword = "search.brave.com";
      DefaultSearchProviderSearchURL = "https://search.brave.com/search?q={searchTerms}";
      DefaultSearchProviderIconURL = "https://cdn.search.brave.com/serp/favicon.ico";
      DefaultSearchProviderEncodings = ["UTF-8"];
      DeveloperToolsAvailability = 1;
      HomepageLocation = homePage;
      HomepageIsNewTabPage = false;
      MetricsReportingEnabled = false;
      PasswordManagerEnabled = true;

      # Open the extension-backed new tab page at startup.
      RestoreOnStartup = 5;

      SearchSuggestEnabled = true;
      ShowHomeButton = false;
      SyncDisabled = false;

      ExtensionInstallAllowlist = map (ext: ext.id) webStoreExtensions;

      SiteSearchSettings = [
      ];

      SpellcheckEnabled = true;
      SpellcheckLanguage = ["en-US"];
    };

    # The upstream HM module writes preferences to the Default profile only.
    # Since this config launches Profile, leave this empty and use the
    # activation hook below instead.
    preferences = {};
  };

  xdg.configFile = lib.listToAttrs (
    map (ext: {
      name = "net.imput.helium/External Extensions/${ext.id}.json";
      value.source = externalExtensionJson ext;
    })
    webStoreExtensions
  );

  home.activation.heliumProfilePreferences = lib.hm.dag.entryAfter ["writeBoundary"] ''
    prefs_dir="$HOME/.config/net.imput.helium/${heliumProfileDir}"
    prefs_file="$prefs_dir/Preferences"
    nix_prefs='${builtins.toJSON profilePreferences}'

    run mkdir -p "$prefs_dir"

    if [ -f "$prefs_file" ]; then
      merged=$(${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$prefs_file" - <<< "$nix_prefs")
      if [ -n "$merged" ]; then
        printf '%s\n' "$merged" > "$prefs_file"
      fi
    else
      printf '%s\n' "$nix_prefs" > "$prefs_file"
    fi

    local_state_dir="$HOME/.config/net.imput.helium"
    local_state_file="$local_state_dir/Local State"
    local_state_fallback='{"browser":{"enabled_labs_experiments":["vertical-tabs@1"]}}'

    run mkdir -p "$local_state_dir"

    if [ -f "$local_state_file" ]; then
      merged=$(${pkgs.jq}/bin/jq '
        .browser.enabled_labs_experiments =
          (((.browser.enabled_labs_experiments // []) + ["vertical-tabs@1"]) | unique)
      ' "$local_state_file")
      if [ -n "$merged" ]; then
        printf '%s\n' "$merged" > "$local_state_file"
      fi
    else
      printf '%s\n' "$local_state_fallback" > "$local_state_file"
    fi

    sessions_dir="$HOME/.config/net.imput.helium/${heliumProfileDir}/Sessions"

    if [ -d "$sessions_dir" ]; then
      for session_file in "$sessions_dir"/Session_* "$sessions_dir"/Tabs_*; do
        if [ -f "$session_file" ] && ${pkgs.binutils}/bin/strings "$session_file" | ${pkgs.gnugrep}/bin/grep -q 'http://0.0.0.1/'; then
          run rm -f "$session_file"
        fi
      done
    fi
  '';
}
