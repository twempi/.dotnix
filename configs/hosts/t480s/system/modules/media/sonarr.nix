{
  flake.modules.nixos.t480s-sonarr = {
    config,
    lib,
    pkgs,
    ...
  }: let
    sonarrPort = 8989;
  in {
    services.sonarr.enable = true;

    users.users.sonarr.extraGroups = ["media"];

    # Group-writable output so edward, Sonarr, and qBittorrent can move and delete each other's files.
    systemd.services.sonarr.serviceConfig.UMask = lib.mkForce "0002";

    sops.secrets.sonarr_api_key.sopsFile = ../../../../../../secrets/sonarr.yaml;

    # Syncs the TRaSH anime profile as its own "Anime (TRaSH)" profile, so the hand-made
    # "Anime" profile is left alone until series are moved over.
    services.recyclarr = {
      enable = true;
      configuration.sonarr.anime = {
        base_url = "http://127.0.0.1:${toString sonarrPort}";
        api_key._secret = config.sops.secrets.sonarr_api_key.path;
        quality_profiles = [
          {
            trash_id = "20e0fc959f1f1704bed501f23bdae76f"; # [Anime] Remux-1080p
            name = "Anime (TRaSH)";
            reset_unmatched_scores.enabled = true;
            upgrade = {
              allowed = false;
              until_quality = "Bluray 1080p";
            };
            # 1080p only, like the hand-made profile. The guide also allows 720p and below.
            qualities = [
              {
                name = "Bluray 1080p";
                qualities = ["Bluray-1080p Remux" "Bluray-1080p"];
              }
              {
                name = "WEB 1080p";
                qualities = ["WEBDL-1080p" "WEBRip-1080p" "HDTV-1080p"];
              }
            ];
          }
        ];
      };
    };

    # Admin UI stays off the LAN.
    networking.firewall.interfaces.tailscale0.allowedTCPPorts = [sonarrPort];

    systemd.services.tailscale-serve-sonarr = import ../_tailscale-serve-service.nix {
      inherit pkgs;
      name = "sonarr";
      description = "Expose Sonarr as a Tailscale Service";
      port = sonarrPort;
    };
  };
}
