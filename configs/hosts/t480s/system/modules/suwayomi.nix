{pkgs, ...}: let
  suwayomiPort = 8080;

  suwayomiVersion = "2.3.2243";

  suwayomiLatest = pkgs.suwayomi-server.overrideAttrs (old: {
    version = suwayomiVersion;

    src = pkgs.fetchurl {
      url = "https://github.com/Suwayomi/Suwayomi-Server/releases/download/v${suwayomiVersion}/Suwayomi-Server-v${suwayomiVersion}.jar";

      hash = "sha256-ghFBsy4XDUoC08vf7Vd+2PB70iOD/19BMuu1rkDpjdU=";
    };
  });
in {
  services.suwayomi-server = {
    enable = true;

    # Use newer upstream Suwayomi instead of nixpkgs' currently stale 2.1.1867 package.
    package = suwayomiLatest;

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
