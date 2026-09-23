{inputs, ...}: {
  imports = [
    inputs.helium.nixosModules.default
  ];

  programs.helium = {
    enable = true;

    policies = {
      AutofillAddressEnabled = false;
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
      HomepageIsNewTabPage = true;
      MetricsReportingEnabled = false;
      PasswordManagerEnabled = false;
      RestoreOnStartup = 5;
      SearchSuggestEnabled = true;
      ShowHomeButton = false;
      SpellcheckEnabled = true;
      SpellcheckLanguage = ["en-US"];
    };
  };
}
