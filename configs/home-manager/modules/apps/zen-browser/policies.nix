{
  flake.modules.homeManager.zen-browser = {lib, ...}: {
    programs.zen-browser.policies = let
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
  };
}
