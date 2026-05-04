{
  pkgs,
  lib,
  inputs,
  ...
}: {
  imports = [
    inputs.zen-browser.homeModules.beta
  ];

  stylix.targets.zen-browser = {
    enable = true;
    profileNames = ["edward"];
  };

  programs.zen-browser = {
    enable = true;
    setAsDefaultBrowser = false;
    nativeMessagingHosts = [pkgs.firefoxpwa];

    policies = let
      mkLockedAttrs = lib.mapAttrs (_: value: {
        Value = value;
        Status = "locked";
      });

      mkPluginUrl = id: "https://addons.mozilla.org/firefox/downloads/latest/${id}/latest.xpi";

      mkExtensionEntry = {
        id,
        pinned ? false,
      }: {
        install_url = mkPluginUrl id;
        installation_mode = "force_installed";

        default_area =
          if pinned
          then "navbar"
          else "menupanel";
      };

      mkExtensionSettings = lib.mapAttrs (_: entry:
        if lib.isAttrs entry
        then entry
        else mkExtensionEntry {id = entry;});
    in {
      AutofillAddressEnabled = true;
      AutofillCreditCardEnabled = false;
      DisableAppUpdate = true;
      DisableFeedbackCommands = true;
      DisableFirefoxStudies = true;
      DisablePocket = true;
      DisableTelemetry = true;
      DontCheckDefaultBrowser = true;
      NoDefaultBookmarks = true;
      OfferToSaveLogins = true;

      EnableTrackingProtection = {
        Value = true;
        Locked = true;
        Cryptomining = true;
        Fingerprinting = true;
      };

      SanitizeOnShutdown = {
        FormData = true;
        Cache = true;
      };

      ExtensionSettings = mkExtensionSettings {
        "wappalyzer@crunchlabz.com" = mkExtensionEntry {
          id = "wappalyzer";
          pinned = false;
        };
        "uBlock0@raymondhill.net" = mkExtensionEntry {
          id = "ublock-origin";
          pinned = true;
        };
        "custom-new-tab-page@mint.as" = mkExtensionEntry {
          id = "custom-new-tab-page";
          pinned = false;
        };
        "languagetool-webextension@languagetool.org" = mkExtensionEntry {
          id = "languagetool";
          pinned = false;
        };
        "jid1-BoFifL9Vbdl2zQ@jetpack" = mkExtensionEntry {
          id = "decentraleyes";
          pinned = false;
        };
        "{85860b32-02a8-431a-b2b1-40fbd64c9c69}" = mkExtensionEntry {
          id = "file-icons-for-github-and-gitlab";
          pinned = false;
        };
        "github-no-more@ihatereality.space" = mkExtensionEntry {
          id = "github-no-more";
          pinned = false;
        };
        "jid1-MnnxcxisBPnSXQ@jetpack" = mkExtensionEntry {
          id = "privacy-badger";
          pinned = false;
        };
        "@searchengineadremover" = mkExtensionEntry {
          id = "search-engine-ad-remover";
          pinned = false;
        };
        "sponsorBlocker@ajay.app" = mkExtensionEntry {
          id = "sponsorblock";
          pinned = false;
        };
        "trackmenot@mrl.nyu.edu" = mkExtensionEntry {
          id = "trackmenot";
          pinned = false;
        };
        "{a4c4eda4-fb84-4a84-b4a1-f7c1cbf2a1ad}" = mkExtensionEntry {
          id = "refined-github-";
          pinned = false;
        };
        "{762f9885-5a13-4abd-9c77-433dcd38b8fd}" = mkExtensionEntry {
          id = "return-youtube-dislikes";
          pinned = false;
        };
        "{74145f27-f039-47ce-a470-a662b129930a}" = mkExtensionEntry {
          id = "clearurls";
          pinned = false;
        };
        "{00000f2a-7cde-4f20-83ed-434fcb420d71}" = mkExtensionEntry {
          id = "imagus";
          pinned = false;
        };
        "{3c6bf0cc-3ae2-42fb-9993-0d33104fdcaf}" = mkExtensionEntry {
          id = "improved-youtube";
          pinned = false;
        };
        "{d7742d87-e61d-4b78-b8a1-b469842139fa}" = mkExtensionEntry {
          id = "vimium";
          pinned = false;
        };
        "{8927f234-4dd9-48b1-bf76-44a9e153eee0}" = mkExtensionEntry {
          id = "better-canvas";
          pinned = false;
        };
        "tasksforcanvas@jtchengdev.com" = mkExtensionEntry {
          id = "tasks-for-canvas";
          pinned = false;
        };
        "{446900e4-71c2-419f-a6a7-df9c091e268b}" = mkExtensionEntry {
          id = "bitwarden-password-manager";
          pinned = false;
        };
      };

      Preferences = mkLockedAttrs {
        "browser.aboutConfig.showWarning" = false;
        "browser.tabs.warnOnClose" = false;
        "browser.tabs.hoverPreview.enabled" = true;

        "browser.newtabpage.activity-stream.feeds.topsites" = false;
        "browser.topsites.contile.enabled" = false;
        "browser.toolbars.bookmarks.visibility" = "always";

        "browser.gesture.swipe.left" = "";
        "browser.gesture.swipe.right" = "";

        "privacy.resistFingerprinting" = true;
        "privacy.resistFingerprinting.randomization.canvas.use_siphash" = true;
        "privacy.resistFingerprinting.randomization.daily_reset.enabled" = true;
        "privacy.resistFingerprinting.randomization.daily_reset.private.enabled" = true;
        "privacy.resistFingerprinting.block_mozAddonManager" = true;
        "privacy.spoof_english" = 1;

        "privacy.firstparty.isolate" = true;
        "network.cookie.cookieBehavior" = 5;
        "dom.battery.enabled" = false;

        "gfx.webrender.all" = true;
        "network.http.http3.enabled" = true;
        "network.socket.ip_addr_any.disabled" = true;
      };

      Homepage = {
        URL = "https://t480s.tailae03d0.ts.net/";
        Locked = true;
        StartPage = "previous-session";
      };
    };

    profiles.edward = rec {
      settings = {
        "zen.workspaces.continue-where-left-off" = true;
        "zen.workspaces.natural-scroll" = true;
        "zen.view.compact.hide-tabbar" = true;
        "zen.view.compact.hide-toolbar" = true;
        "zen.view.compact.animate-sidebar" = false;
        "zen.welcome-screen.seen" = true;
        "zen.urlbar.behavior" = "default";
        "zen.urlbar.replace-newtab" = false;
        "zen.view.sidebar-expanded" = false;
        "zen.view.sidebar-expanded.on-hover" = false;
        "zen.window-sync.enabled" = false;
        "zen.window-sync.prefer-unsynced-windows" = false;

        "browser.uiCustomization.state" = {
          placements = {
            "widget-overflow-fixed-list" = [
              "screenshot-button"
            ];

            "unified-extensions-area" = [
              "wappalyzer_crunchlabz_com-browser-action"
              "_3c6bf0cc-3ae2-42fb-9993-0d33104fdcaf_-browser-action"
              "jid1-mnnxcxisbpnsxq_jetpack-browser-action"
              "trackmenot_mrl_nyu_edu-browser-action"
              "github-repository-size_pranavmangal-browser-action"
              "_85860b32-02a8-431a-b2b1-40fbd64c9c69_-browser-action"
              "_a4c4eda4-fb84-4a84-b4a1-f7c1cbf2a1ad_-browser-action"
              "_861a3982-bb3b-49c6-bc17-4f50de104da1_-browser-action"
              "_762f9885-5a13-4abd-9c77-433dcd38b8fd_-browser-action"
              "_74145f27-f039-47ce-a470-a662b129930a_-browser-action"
              "_3579f63b-d8ee-424f-bbb6-6d0ce3285e6a_-browser-action"
              "firefox-extension_steamdb_info-browser-action"
              "jid1-bofifl9vbdl2zq_jetpack-browser-action"
              "languagetool-webextension_languagetool_org-browser-action"
              "myallychou_gmail_com-browser-action"
              "addon_darkreader_org-browser-action"
              "ogobell3_icloud_com-browser-action"
              "fashionreps-link-converter_example_com-browser-action"
              "newtaboverride_agenedia_com-browser-action"
              "sponsorblocker_ajay_app-browser-action"
            ];

            "nav-bar" = [
              "back-button"
              "forward-button"
              "stop-reload-button"
              "vertical-spacer"
              "urlbar-container"
              "unified-extensions-button"
              "ublock0_raymondhill_net-browser-action"
            ];

            "toolbar-menubar" = [
              "menubar-items"
            ];

            "TabsToolbar" = [
              "tabbrowser-tabs"
            ];

            "vertical-tabs" = [];

            "PersonalToolbar" = [
              "personal-bookmarks"
            ];

            "zen-sidebar-top-buttons" = [];

            "zen-sidebar-foot-buttons" = [
              "downloads-button"
              "zen-workspaces-button"
              "zen-create-new-button"
            ];
          };

          seen = [
            "developer-button"
            "trackmenot_mrl_nyu_edu-browser-action"
            "github-repository-size_pranavmangal-browser-action"
            "_85860b32-02a8-431a-b2b1-40fbd64c9c69_-browser-action"
            "_a4c4eda4-fb84-4a84-b4a1-f7c1cbf2a1ad_-browser-action"
            "_861a3982-bb3b-49c6-bc17-4f50de104da1_-browser-action"
            "_762f9885-5a13-4abd-9c77-433dcd38b8fd_-browser-action"
            "_74145f27-f039-47ce-a470-a662b129930a_-browser-action"
            "_3579f63b-d8ee-424f-bbb6-6d0ce3285e6a_-browser-action"
            "ublock0_raymondhill_net-browser-action"
            "firefox-extension_steamdb_info-browser-action"
            "jid1-bofifl9vbdl2zq_jetpack-browser-action"
            "screenshot-button"
            "wappalyzer_crunchlabz_com-browser-action"
            "sponsorblocker_ajay_app-browser-action"
            "languagetool-webextension_languagetool_org-browser-action"
            "_3c6bf0cc-3ae2-42fb-9993-0d33104fdcaf_-browser-action"
            "jid1-mnnxcxisbpnsxq_jetpack-browser-action"
            "myallychou_gmail_com-browser-action"
            "addon_darkreader_org-browser-action"
            "ogobell3_icloud_com-browser-action"
            "fashionreps-link-converter_example_com-browser-action"
            "newtaboverride_agenedia_com-browser-action"
          ];

          dirtyAreaCache = [
            "nav-bar"
            "vertical-tabs"
            "zen-sidebar-foot-buttons"
            "unified-extensions-area"
            "PersonalToolbar"
            "toolbar-menubar"
            "TabsToolbar"
            "zen-sidebar-top-buttons"
            "widget-overflow-fixed-list"
          ];

          currentVersion = 23;
          newElementCount = 4;
        };
      };

      mods = [
        "1b88a6d1-d931-45e8-b6c3-bfdca2c7e9d6" # Remove Tab X
        # "a5f6a231-e3c8-4ce8-8a8e-3e93efd6adec" # Cleaner URL Bar
        "d8b79d4a-6cba-4495-9ff6-d6d30b0e94fe" # Better Active Tab
        "72f8f48d-86b9-4487-acea-eb4977b18f21" # Better Ctrl Tab Panel
        "253a3a74-0cc4-47b7-8b82-996a64f030d5" # Floating History
      ];

      containersForce = true;
      containers = {
        Personal = {
          color = "purple";
          icon = "fingerprint";
          id = 1;
        };
        Shopping = {
          color = "yellow";
          icon = "dollar";
          id = 2;
        };
      };

      search = {
        force = true;
        default = "google";
        engines = let
          nixIcon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
          chatgptIcon = "https://chatgpt.com/favicon.ico";
        in {
          "Nix Packages" = {
            urls = [
              {
                template = "https://search.nixos.org/packages";
                params = [
                  {
                    name = "type";
                    value = "packages";
                  }
                  {
                    name = "channel";
                    value = "unstable";
                  }
                  {
                    name = "query";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            icon = nixIcon;
            definedAliases = ["np"];
          };

          "Nix Options" = {
            urls = [
              {
                template = "https://search.nixos.org/options";
                params = [
                  {
                    name = "channel";
                    value = "unstable";
                  }
                  {
                    name = "query";
                    value = "{searchTerms}";
                  }
                ];
              }
            ];
            icon = nixIcon;
            definedAliases = ["nop"];
          };

          "ChatGPT" = {
            urls = [
              {
                template = "https://chatgpt.com/";
              }
            ];
            icon = chatgptIcon;
            definedAliases = ["gpt"];
          };

          bing.metaData.hidden = "true";
        };
      };
    };
  };
}
