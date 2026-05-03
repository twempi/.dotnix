# {
#   inputs,
#   lib,
#   pkgs,
#   ...
# }: let
#   homePage = "https://t480s.tailae03d0.ts.net/";
#   heliumProfileDir = "Profile 1";
#
#   profilePreferences = {
#     browser = {
#       show_home_button = false;
#     };
#
#     bookmark_bar = {
#       show_apps_shortcut = false;
#       show_managed_bookmarks = true;
#       show_on_all_tabs = true;
#       show_tab_groups = false;
#     };
#
#     homepage = homePage;
#     homepage_is_newtabpage = true;
#
#     session = {
#       restore_on_startup = 4;
#       startup_urls = [
#         homePage
#       ];
#     };
#
#     autofill = {
#       credit_card_enabled = false;
#       profile_enabled = true;
#     };
#
#     credentials_enable_service = true;
#
#     profile = {
#       password_manager_enabled = true;
#     };
#   };
# in {
#   imports = [inputs.helium.homeModules.helium];
#
#   programs.helium = {
#     enable = true;
#     defaultBrowser = false;
#
#     extensions = [
#       {
#         # AI Grammar Checker & Paraphraser - LanguageTool
#         id = "oldceeleldhonbafppcapldpdifcinji";
#         hash = "sha256-UEVCv/S2Clfzp9mU6c8q/NjAqug5GU4EZnu5z8l/LJE=";
#       }
#       {
#         # File Icons for GitHub and GitLab
#         id = "ficfmibkjjnpogdcfhfokmihanoldbfe";
#         hash = "sha256-r9RsPoGXx/dka1INM9KOddNl6ccHCjHHEqJmcjsUPYM=";
#       }
#       {
#         # SponsorBlock for YouTube
#         id = "mnjggcdmjocbbbhaepdhchncahnbgone";
#         hash = "sha256-nE5FE3Eo1jG8sT1KYjVl8JRbmAiyhN8IZObHsAIb0wY=";
#       }
#       {
#         # Return YouTube Dislike
#         id = "gebbhagfogifgggkldgodflihgfeippi";
#         hash = "sha256-0ZO+7AY5dcy1AOXPtZ9sSPcj9Wl2RQkE9oOFZq7ESqM=";
#       }
#       {
#         # ClearURLs
#         id = "lckanjgmijmafbedllaakclkaicjfmnk";
#         hash = "sha256-rMFzGyrQCJ85p93PDHIy7TU329AZuOjBvuzoeO1Yoxo=";
#       }
#       {
#         # Improve YouTube
#         id = "bnomihfieiccainjcjblhegjgglakjdd";
#         hash = "sha256-xFEBWKB0ZPQ3myFJw9+RK2ohVloHvpA+acL1VK5fUJs=";
#       }
#       {
#         # Vimium
#         id = "dbepggeogbaibhgnhhndojpepiihcmeb";
#         hash = "sha256-MZjCaqcZvkYt6lhQUPvtm4uAYo1X6oihE7q/UzTFUXw=";
#       }
#       {
#         # BetterCampus, previously BetterCanvas
#         id = "cndibmoanboadcifjkjbdpjgfedanolh";
#         hash = "sha256-CtVjiDw/pLBH36QYGbKo/Pu+gxQT1iLdHn70ITRh74c=";
#       }
#       {
#         # Imagus Reborn
#         id = "fcjmgeodgobggcppooncdagfkogfffdm";
#         hash = "sha256-ioqkGne9PJUqoNV//PIfQlG3CIfGzhsXpJmS5Pt5bCM=";
#       }
#       {
#         # Bitwarden Password Manager
#         id = "nngceckbapebfimnlniiiahkandclblb";
#         hash = "sha256-XOVs2Tvay8hQ13SHz+728BDu2mMyQ0JxUuUI6FZ1NaM=";
#       }
#       # {
#       #   # Wappalyzer
#       #   id = "gppongmhjkpfnbhagpmjfkannfbllamg";
#       #   hash = "sha256-...";
#       # }
#       {
#         # Privacy Badger
#         id = "pkehgijcmpdhfbdbbnkijodmdjhbjlgp";
#         hash = "sha256-47DEQpj8HBSa+/TImW+5JCeuQeRkm5NMpJWZG3hSuFU=";
#       }
#       # {
#       #   # Refined GitHub
#       #   id = "hlepfoohegkhhmjieoechaddaejaokhf";
#       #   hash = "sha256-47DEQpj8HBSa+/TImW+5JCeuQeRkm5NMpJWZG3hSuFU=";
#       # }
#     ];
#
#     extraFlags = [
#       "--profile-directory=${heliumProfileDir}"
#       "--force-dark-mode"
#     ];
#
#     extraPolicies = {
#       AutofillAddressEnabled = true;
#       AutofillCreditCardEnabled = false;
#       BackgroundModeEnabled = false;
#       BlockThirdPartyCookies = true;
#       BookmarkBarEnabled = true;
#       BrowserSignin = 0;
#       DefaultBrowserSettingEnabled = false;
#       DefaultSearchProviderEnabled = true;
#       DefaultSearchProviderKeyword = "google.com";
#       DefaultSearchProviderName = "Google";
#       DefaultSearchProviderSearchURL = "https://www.google.com/search?q={searchTerms}";
#       DefaultSearchProviderSuggestURL = "https://www.google.com/complete/search?output=chrome&q={searchTerms}";
#       DeveloperToolsAvailability = 1;
#       HomepageLocation = homePage;
#       HomepageIsNewTabPage = false;
#       MetricsReportingEnabled = false;
#       PasswordManagerEnabled = true;
#       # RestoreOnStartup = 4;
#       # RestoreOnStartupURLs = [
#       #   homePage
#       # ];
#       SearchSuggestEnabled = true;
#       ShowHomeButton = false;
#       SyncDisabled = false;
#
#       # ManagedBookmarks = [
#       #   {
#       #     toplevel_name = "Quick Links";
#       #   }
#       #   {
#       #     name = "Startpage";
#       #     url = homePage;
#       #   }
#       #   {
#       #     name = "Nix Packages";
#       #     url = "https://search.nixos.org/packages?channel=unstable";
#       #   }
#       #   {
#       #     name = "Nix Options";
#       #     url = "https://search.nixos.org/options?channel=unstable";
#       #   }
#       #   {
#       #     name = "ChatGPT";
#       #     url = "https://chatgpt.com/";
#       #   }
#       # ];
#
#       NewTabPageLocation = homePage;
#
#       SiteSearchSettings = [
#         {
#           featured = true;
#           name = "Nix Packages";
#           shortcut = "np";
#           url = "https://search.nixos.org/packages?channel=unstable&query={searchTerms}";
#         }
#         {
#           featured = true;
#           name = "Nix Options";
#           shortcut = "nop";
#           url = "https://search.nixos.org/options?channel=unstable&query={searchTerms}";
#         }
#         {
#           featured = true;
#           name = "ChatGPT";
#           shortcut = "gpt";
#           url = "https://https://chatgpt.com/";
#         }
#       ];
#
#       SpellcheckEnabled = true;
#       SpellcheckLanguage = ["en-US"];
#     };
#
#     preferences = profilePreferences;
#   };
#
#   # home.activation.heliumProfilePreferences = lib.hm.dag.entryAfter ["writeBoundary"] ''
#   #   prefs_dir="$HOME/.config/net.imput.helium/${heliumProfileDir}"
#   #   prefs_file="$prefs_dir/Preferences"
#   #   nix_prefs='${builtins.toJSON profilePreferences}'
#   #
#   #   run mkdir -p "$prefs_dir"
#   #
#   #   if [ -f "$prefs_file" ]; then
#   #     merged=$(${pkgs.jq}/bin/jq -s '.[0] * .[1]' "$prefs_file" - <<< "$nix_prefs")
#   #     if [ -n "$merged" ]; then
#   #       printf '%s\n' "$merged" > "$prefs_file"
#   #     fi
#   #   else
#   #     printf '%s\n' "$nix_prefs" > "$prefs_file"
#   #   fi
#   # '';
# }
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

  heliumBase = inputs.helium.packages.${pkgs.stdenv.hostPlatform.system}.helium;

  # The upstream helium-flake wrapper currently adds --restore-last-session.
  # This wrapper keeps the useful upstream runtime flags, but intentionally
  # leaves out --restore-last-session so startup policy can actually win.
  heliumNoRestorePackage =
    if pkgs.stdenv.isLinux
    then
      pkgs.symlinkJoin {
        name = "helium-no-restore";
        paths = [heliumBase];
        nativeBuildInputs = [pkgs.makeWrapper];

        postBuild = ''
          rm -f $out/bin/helium

          makeWrapper ${heliumBase}/opt/helium/helium $out/bin/helium \
            --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath [
            pkgs.libGL
            pkgs.libvdpau
            pkgs.libva
            pkgs.pipewire
            pkgs.alsa-lib
            pkgs.libpulseaudio
          ]}" \
            --add-flags "--ozone-platform-hint=auto" \
            --add-flags "--enable-features=WaylandWindowDecorations" \
            --add-flags "--disable-component-update" \
            --add-flags "--simulate-outdated-no-au='Tue, 31 Dec 2099 23:59:59 GMT'" \
            --add-flags "--check-for-update-interval=0" \
            --add-flags "--no-first-run" \
            --add-flags "--enable-features=StorageAccessAPI"
        '';
      }
    else heliumBase;

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
    package = heliumNoRestorePackage;
    defaultBrowser = false;

    extensions = [
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
      # Imagus Reborn intentionally removed from `extensions`.
      # BetterCampus is also intentionally removed from `extensions`; its
      # unpacked-extension startup behavior opens Canvas on every launch.
      # Both are installed below with ExtensionInstallForcelist instead of
      # being loaded via --load-extension.
      {
        # Bitwarden Password Manager
        id = "nngceckbapebfimnlniiiahkandclblb";
        hash = "sha256-XOVs2Tvay8hQ13SHz+728BDu2mMyQ0JxUuUI6FZ1NaM=";
      }
      # {
      #   # Wappalyzer
      #   id = "gppongmhjkpfnbhagpmjfkannfbllamg";
      #   hash = "sha256-...";
      # }
      # {
      #   # Privacy Badger
      #   id = "pkehgijcmpdhfbdbbnkijodmdjhbjlgp";
      #   hash = "sha256-47DEQpj8HBSa+/TImW+5JCeuQeRkm5NMpJWZG3hSuFU=";
      # }
      # {
      #   # Refined GitHub
      #   id = "hlepfoohegkhhmjieoechaddaejaokhf";
      #   hash = "sha256-47DEQpj8HBSa+/TImW+5JCeuQeRkm5NMpJWZG3hSuFU=";
      # }
    ];

    extraFlags = [
      "--profile-directory=${heliumProfileDir}"
      "--force-dark-mode"
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

      # Open the configured homepage URL at startup.
      RestoreOnStartup = 4;
      RestoreOnStartupURLs = [
        homePage
      ];

      SearchSuggestEnabled = true;
      ShowHomeButton = true;
      SyncDisabled = false;

      # Install extensions whose unpacked startup behavior should not run on
      # every Helium launch as managed Web Store extensions instead.
      ExtensionInstallForcelist = [
        "fcjmgeodgobggcppooncdagfkogfffdm;https://clients2.google.com/service/update2/crx"
        "cndibmoanboadcifjkjbdpjgfedanolh;https://clients2.google.com/service/update2/crx"
      ];

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
        {
          featured = true;
          name = "ChatGPT";
          shortcut = "gpt";
          url = "https://chatgpt.com/";
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
