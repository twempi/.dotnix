{
  flake.modules.homeManager.librewolf = {
    stylix.targets.librewolf = {
      enable = true;
      profileNames = [
        "edward"
      ];
    };

    programs.librewolf = {
      enable = true;

      policies = {
        AutofillAddressEnabled = false;
        AutofillCreditCardEnabled = false;
        Cookies = {
          Behavior = "reject-foreign";
          BehaviorPrivateBrowsing = "reject-foreign";
          Locked = true;
        };
        DisableFirefoxAccounts = true;
        DisplayBookmarksToolbar = "always";
        OfferToSaveLogins = false;
        PasswordManagerEnabled = false;
        SearchSuggestEnabled = true;

        Handlers.schemes.discord = {
          action = "useSystemDefault";
          ask = false;
        };
      };

      profiles.edward = {
        settings = {
          # The local extensions are unsigned.
          "xpinstall.signatures.required" = false;

          # Helium keeps logins across restarts.
          "privacy.sanitize.sanitizeOnShutdown" = false;

          # privacy.resistFingerprinting pins prefers-color-scheme to light and
          # has no per-target override; this keeps every other protection.
          "privacy.resistFingerprinting" = false;
          "privacy.fingerprintingProtection" = true;
          "privacy.fingerprintingProtection.overrides" = "+AllTargets,-CSSPrefersColorScheme";

          "sidebar.verticalTabs" = true;
          "sidebar.backupState" = builtins.toJSON {
            launcherExpanded = false;
            launcherVisible = true;
            panelOpen = false;
          };

          "layout.spellcheckDefault" = 2;
          "spellchecker.dictionary" = "en-US";
        };

        # Matches Helium's vertical tab width; there is no pref for it.
        userChrome = ":root { --sidebar-expanded-launcher-width: 200px !important; }";

        search = {
          force = true;
          default = "brave";
          privateDefault = "brave";
          engines.brave = {
            name = "Brave Search";
            urls = [
              {
                template = "https://search.brave.com/search";
                params = [
                  {
                    name = "q";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            icon = "https://cdn.search.brave.com/serp/favicon.ico";
            definedAliases = ["search.brave.com"];
          };
        };
      };
    };
  };
}
