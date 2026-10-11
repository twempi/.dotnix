{
  pkgs,
  inputs,
  ...
}: let
  suwayomiPort = 8080;
  extensionStoreUrl = "https://raw.githubusercontent.com/keiyoushi/extensions/repo/index.min.json";
in {
  services.suwayomi-server = {
    enable = true;

    package = inputs.suwayomi.packages.${pkgs.stdenv.hostPlatform.system}.default;

    # Tailscale Serve exposes it, so don't open this on LAN/Wi-Fi.
    openFirewall = false;

    settings.server = {
      ip = "127.0.0.1";
      port = suwayomiPort;

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
      webUIChannel = "bundled";
      # Disable scheduled WebUI update checks; retain bundled assets with the server release.
      webUIUpdateCheckInterval = 0;

      # Keep the legacy setting in sync with the v2.3 extension store setting.
      extensionRepos = [
        extensionStoreUrl
      ];
      extensionStores = [
        extensionStoreUrl
      ];
    };
  };

  services.flaresolverr = {
    enable = true;
    port = 8191;
    openFirewall = false;
  };

  systemd.services.tailscale-serve-suwayomi = {
    description = "Expose Suwayomi as a Tailscale Service";
    after = ["tailscaled.service"];
    wants = ["tailscaled.service"];
    wantedBy = ["multi-user.target"];

    restartIfChanged = true;

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      TimeoutStartSec = 30;
    };

    script = ''
      set -euo pipefail

      ${pkgs.util-linux}/bin/flock -w 120 /run/tailscale-serve.lock \
        ${pkgs.tailscale}/bin/tailscale serve --yes --bg \
          --service=svc:suwayomi \
          --https=${toString suwayomiPort} \
          http://127.0.0.1:${toString suwayomiPort}
    '';
  };
}
