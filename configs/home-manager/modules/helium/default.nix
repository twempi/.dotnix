{inputs, ...}: {
  imports = [inputs.helium.homeModules.helium];

  programs.helium = {
    enable = true;
    defaultBrowser = false;

    extraPolicies = {
      HomepageLocation = "https://t480s.tailae03d0.ts.net/";
      HomepageIsNewTabPage = true;
      ShowHomeButton = false;

      NewTabPageLocation = "https://www.chromium.org";

      SpellcheckEnabled = true;
      SpellcheckLanguage = ["en-US"];
    };

    preferences = {
      browser.show_home_button = false;
      bookmark_bar.show_on_all_tabs = true;
    };
  };
}
