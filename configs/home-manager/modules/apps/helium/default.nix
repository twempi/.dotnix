{
  inputs,
  lib,
  pkgs,
  ...
}: let
  homePage = "https://t480s.tailae03d0.ts.net/";
  # Local State shows Helium is using Profile. Profile 1 made the wrapper emit
  # a space-containing flag, leaving a stray `1` argument that Chromium opened
  # as http://0.0.0.1/.
  heliumProfileDir = "Profile";

  startpageSource = ../../../../hosts/t480s/system/modules/caddy/startpage;

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

  unpackExtension = {
    id,
    hash,
  }:
    pkgs.runCommand "helium-ext-${id}" {
      nativeBuildInputs = [pkgs.unzip];
      src = fetchExtension {inherit id hash;};
    } ''
      mkdir -p $out
      unzip -q $src -d $out || true
      rm -rf $out/_metadata
    '';

  unpackedWebStoreExtensions = map unpackExtension webStoreExtensions;

  localNewTabExtension = pkgs.runCommand "helium-new-tab-startpage" {} ''
    mkdir -p $out
    cp -r ${startpageSource}/* $out/
    cp ${./new-tab-startpage/manifest.json} $out/manifest.json
  '';

  allUnpackedExtensionPaths = map toString (unpackedWebStoreExtensions ++ [localNewTabExtension]);

  profilePreferences = {
    browser = {
      show_home_button = true;
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
      enabled = true;
    };

    autofill = {
      credit_card_enabled = false;
      profile_enabled = true;
    };

    credentials_enable_service = true;

    profile = {
      password_manager_enabled = true;
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
      DefaultSearchProviderKeyword = "google.com";
      DefaultSearchProviderName = "Google";
      DefaultSearchProviderSearchURL = "https://www.google.com/search?q={searchTerms}";
      DefaultSearchProviderSuggestURL = "https://www.google.com/complete/search?output=chrome&q={searchTerms}";
      DeveloperToolsAvailability = 1;
      HomepageLocation = homePage;
      HomepageIsNewTabPage = false;
      MetricsReportingEnabled = false;
      PasswordManagerEnabled = true;

      # Open a new tab at startup; the local extension provides the startpage.
      RestoreOnStartup = 5;

      SearchSuggestEnabled = true;
      ShowHomeButton = true;
      SyncDisabled = false;

      # Install extensions whose unpacked startup behavior should not run on
      # every Helium launch as managed Web Store extensions instead.
      ExtensionInstallForcelist = [
        "fcjmgeodgobggcppooncdagfkogfffdm;https://clients2.google.com/service/update2/crx"
        "cndibmoanboadcifjkjbdpjgfedanolh;https://clients2.google.com/service/update2/crx"
      ];

      ExtensionInstallAllowlist = map (ext: ext.id) webStoreExtensions;

      # ManagedBookmarks = [
      #   {
      #     toplevel_name = "Quick Links";
      #   }
      #   {
      #     name = "Startpage";
      #     url = homePage;
      #   }
      #   {
      #     name = "Nix Packages";
      #     url = "https://search.nixos.org/packages?channel=unstable";
      #   }
      #   {
      #     name = "Nix Options";
      #     url = "https://search.nixos.org/options?channel=unstable";
      #   }
      #   {
      #     name = "ChatGPT";
      #     url = "https://chatgpt.com/";
      #   }
      # ];
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
      ];

      SpellcheckEnabled = true;
      SpellcheckLanguage = ["en-US"];
    };

    # The upstream HM module writes preferences to the Default profile only.
    # Since this config launches Profile, leave this empty and use the
    # activation hook below instead.
    preferences = {};
  };

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
