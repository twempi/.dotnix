{
  inputs,
  lib,
  pkgs,
  ...
}: let
  homePage = "https://t480s.tailae03d0.ts.net/";
  heliumProfileDir = "Profile 1";

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
      restore_on_startup = 4;
      startup_urls = [
        homePage
      ];
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
    defaultBrowser = false;

    extensions = [
      # uBlock Origin is bundled with Helium, so avoid loading a duplicate CRX.
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
        # BetterCampus, previously BetterCanvas
        id = "cndibmoanboadcifjkjbdpjgfedanolh";
        hash = "sha256-CtVjiDw/pLBH36QYGbKo/Pu+gxQT1iLdHn70ITRh74c=";
      }
      # Tasks for Canvas has a valid CRX, but the Helium flake unpack step fails
      # on its _metadata directory permissions.
      # {
      #   # Tasks for Canvas
      #   id = "kabafodfnabokkkddjbnkgbcbmipdlmb";
      #   hash = "sha256-/C78Zkr4PrQp6YOcw3fQDByJNduegPwWkKd/cVku7YU=";
      # }
      {
        # Imagus Reborn
        id = "fcjmgeodgobggcppooncdagfkogfffdm";
        hash = "sha256-ioqkGne9PJUqoNV//PIfQlG3CIfGzhsXpJmS5Pt5bCM=";
      }
      # Wappalyzer's Google CRX endpoint currently resolves to an empty file with
      # the Helium flake fetch URL, so enabling it would load an empty extension.
      # {
      #   # Wappalyzer
      #   id = "gppongmhjkpfnbhagpmjfkannfbllamg";
      #   hash = "sha256-...";
      # }
      # {
      #   # Privacy Badger
      #   id = "pkehgijcmpdhfbdbbnkijodmdjhbjlgp";
      #   hash = "sha256-...";
      # }
      # {
      #   # Refined GitHub
      #   id = "hlepfoohegkhhmjieoechaddaejaokhf";
      #   hash = "sha256-...";
      # }
    ];

    extraFlags = [
      "--profile-directory=${heliumProfileDir}"
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
      RestoreOnStartup = 4;
      RestoreOnStartupURLs = [
        homePage
      ];
      SearchSuggestEnabled = true;
      ShowHomeButton = false;
      SyncDisabled = false;

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

      NewTabPageLocation = homePage;

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

    preferences = profilePreferences;
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
  '';
}
