{
  extensionIds,
  homePage,
}: {
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

  # Open the local extension through Chromium's New Tab Page.
  RestoreOnStartup = 5;

  SearchSuggestEnabled = true;
  ShowHomeButton = false;
  SyncDisabled = false;

  ExtensionInstallAllowlist = extensionIds;

  SiteSearchSettings = [
  ];

  SpellcheckEnabled = true;
  SpellcheckLanguage = ["en-US"];
}
