{
  services.suwayomi-server = {
    enable = true;
    openFirewall = true;

    settings.server = {
      ip = "0.0.0.0";
      port = 8080;

      flareSolverrEnabled = true;
      flareSolverrUrl = "http://127.0.0.1:8191";
      flareSolverrTimeout = 60;
      flareSolverrSessionName = "suwayomi";
      flareSolverrSessionTtl = 15;
      flareSolverrAsResponseFallback = true;

      webUIEnabled = true;
      initialOpenInBrowserEnabled = true;
      webUIInterface = "browser"; # "browser" or "electron"
      webUIFlavor = "WebUI"; # "WebUI" or "Custom"
      webUIChannel = "stable"; # "BUNDLED" or "STABLE" or "PREVIEW"
      webUIUpdateCheckInterval = 23;

      extensionRepos = [
        "https://raw.githubusercontent.com/keiyoushi/extensions/repo/index.min.json"
      ];
    };
  };

  services.flaresolverr = {
    enable = true;
    port = 8191;
    openFirewall = false;
  };
}
