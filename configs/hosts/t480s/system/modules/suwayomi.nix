{...}: let
  suwayomiInternalPort = 8080;
  suwayomiExternalPort = 8080;
in {
  services.suwayomi-server = {
    enable = true;

    # Tailscale Serve will expose it, so don't open this on LAN/Wi-Fi.
    openFirewall = false;

    settings.server = {
      ip = "127.0.0.1";
      port = suwayomiInternalPort;

      flareSolverrEnabled = true;
      flareSolverrUrl = "http://127.0.0.1:8191";
      flareSolverrTimeout = 60;
      flareSolverrSessionName = "suwayomi";
      flareSolverrSessionTtl = 15;
      flareSolverrAsResponseFallback = true;

      webUIEnabled = true;
      initialOpenInBrowserEnabled = true;
      webUIInterface = "browser";
      webUIFlavor = "WebUI";
      webUIChannel = "stable";
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

  services.tailscale.serve.services.suwayomi = {
    endpoints = {
      "tcp:${toString suwayomiExternalPort}" = "http://127.0.0.1:${toString suwayomiInternalPort}";
    };

    advertised = true;
  };
}
