{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  homePage = "https://t480s.tailae03d0.ts.net/";

  heliumProfileDir = "Profile";

  mkStylixStartpage = import ../../../../hosts/t480s/system/modules/caddy/startpage/lib/mkStylixStartpage.nix;
  stylixStartpage = mkStylixStartpage {
    inherit pkgs;
    source = ../../../../hosts/t480s/system/modules/caddy/startpage;
    colors = config.lib.stylix.colors;
    fontFamily = config.stylix.fonts.monospace.name;
  };

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

  localNewTabExtension = pkgs.runCommand "helium-new-tab-startpage" {} ''
    mkdir -p $out
    cp -r ${stylixStartpage}/* $out/
    cp ${./new-tab-startpage/manifest.json} $out/manifest.json
    mkdir -p $out/icons
    cp ${./new-tab-startpage/icons/16.png} $out/icons/16.png
    cp ${./new-tab-startpage/icons/32.png} $out/icons/32.png
    cp ${./new-tab-startpage/icons/48.png} $out/icons/48.png
    cp ${./new-tab-startpage/icons/128.png} $out/icons/128.png
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
      restore_on_startup = 6;
      startup_urls = [homePage];
    };

    vertical_tabs = {
      enabled = true;
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

      # Open a new tab at startup; the local extension provides the startpage.
      RestoreOnStartup = 6;
      RestoreOnStartupURLs = [
        homePage
      ];

      SearchSuggestEnabled = true;
      ShowHomeButton = false;
      SyncDisabled = false;

      ExtensionInstallAllowlist = map (ext: ext.id) webStoreExtensions;

      SiteSearchSettings = [
        {
          featured = true;
          name = "Nix Packages";
          shortcut = "np";
          url = "https://search.nixos.org/packages?channel=unstable&query={searchTerms}";
        }
        {
          featured = true;
          name = "Nix Options";
          shortcut = "nop";
          url = "https://search.nixos.org/options?channel=unstable&query={searchTerms}";
        }
        {
          featured = true;
          name = "ChatGPT";
          shortcut = "gpt";
          url = "https://chatgpt.com/?q={searchTerms}";
        }
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
