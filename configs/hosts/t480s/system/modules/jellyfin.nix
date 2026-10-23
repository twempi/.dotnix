{
  flake.modules.nixos.t480s-jellyfin = let
    libraryDir = "/srv/anime";
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

    users.users.jellyfin.extraGroups = ["render" "video"];

    # edward manages the files; jellyfin reads them through the group. setgid keeps new show folders in that group.
    systemd.tmpfiles.rules = [
      "d ${libraryDir} 2750 edward jellyfin - -"
    ];

    networking.firewall.interfaces = {
      enp0s31f6.allowedTCPPorts = [8096];
      tailscale0.allowedTCPPorts = [8096];
    };
  };
}
