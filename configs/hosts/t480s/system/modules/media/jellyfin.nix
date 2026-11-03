{
  flake.modules.nixos.t480s-jellyfin = {pkgs, ...}: let
    libraryDir = "/srv/anime";
    jellyfinPort = 8096;
  in {
    services.jellyfin = {
      enable = true;
      openFirewall = false;

      hardwareAcceleration = {
        enable = true;
        type = "vaapi";
        device = "/dev/dri/renderD128";
      };

      # Make this config the source of truth; dashboard transcoding edits are reset on restart.
      forceEncodingConfig = true;
      transcoding = {
        enableHardwareEncoding = true;
        hardwareDecodingCodecs = {
          h264 = true;
          hevc = true;
          hevc10bit = true;
        };
      };
    };

    users.users.jellyfin.extraGroups = ["render" "video" "media"];

    # Shared through the media group with Sonarr and qBittorrent. setgid keeps new show folders in that group.
    systemd.tmpfiles.rules = [
      "d ${libraryDir} 2770 edward media - -"
    ];

    networking.firewall.interfaces = {
      enp0s31f6.allowedTCPPorts = [jellyfinPort];
      tailscale0.allowedTCPPorts = [jellyfinPort];
    };

    systemd.services.tailscale-serve-jellyfin = import ../_tailscale-serve-service.nix {
      inherit pkgs;
      name = "jellyfin";
      description = "Expose Jellyfin as a Tailscale Service";
      port = jellyfinPort;
    };
  };
}
