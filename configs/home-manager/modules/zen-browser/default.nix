{
  pkgs,
  lib,
  config,
  inputs,
  ...
}: {
  imports = [
    inputs.zen-browser.homeModules.beta
  ];

  stylix.targets.zen-browser.profileNames = ["edward"];

  programs.zen-browser = {
    enable = true;

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

        # Only uBO goes on the toolbar; everything else stays unpinned in the menu.
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
        "{a4c4eda4-fb84-4a84-b4a1-f7c1cbf2a1ad}" = "refined-github-";
        "{762f9885-5a13-4abd-9c77-433dcd38b8fd}" = "return-youtube-dislikes";
        "{74145f27-f039-47ce-a470-a662b129930a}" = "clearurls";
        "newtaboverride@agenedia.com" = "new-tab-override";
        "{00000f2a-7cde-4f20-83ed-434fcb420d71}" = "imagus";
        "{3c6bf0cc-3ae2-42fb-9993-0d33104fdcaf}" = "improved-youtube";
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
        URL = "http://127.0.0.1:8000/index.html";
        Locked = true;
        StartPage = "homepage";
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
        "zen.window-sync.enabled" = true;
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

          bing.metaData.hidden = "true";
        };
      };
    };
  };
}
