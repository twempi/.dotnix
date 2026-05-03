{
  config,
  pkgs,
  ...
}: let
  # CHANGE THIS after you know your Tailscale HTTPS name.
  #
  # It will look something like:
  # https://my-laptop.tailabc123.ts.net
  vaultwardenUrl = "https://t480s.tailae03d0.ts.net";

  vaultwardenPort = 8222;
in {
  services.vaultwarden = {
    enable = true;

    # SQLite is fine for personal/family use.
    dbBackend = "sqlite";

    # Secrets go here so they are not written into the Nix store.
    environmentFile = "/var/lib/vaultwarden/vaultwarden.env";

    # NixOS-provided backup location.
    backupDir = "/var/backup/vaultwarden";

    config = {
      DOMAIN = vaultwardenUrl;

      # First-time setup:
      # Set this to true temporarily, create your account,
      # then change it back to false.
      SIGNUPS_ALLOWED = true;

      # Keep Vaultwarden private on localhost.
      # Tailscale Serve will expose it over HTTPS to your tailnet.
      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = vaultwardenPort;
      ROCKET_LOG = "critical";

      # Good beginner security defaults.
      SHOW_PASSWORD_HINT = false;
      INVITATIONS_ALLOWED = true;

      # You can configure email later.
      # Without SMTP, some invite/password-reset email features will not work.
    };
  };

  services.tailscale.enable = true;

  systemd.tmpfiles.rules = [
    "d /var/lib/vaultwarden 0750 vaultwarden vaultwarden -"
    "d /var/backup/vaultwarden 0750 vaultwarden vaultwarden -"
  ];

  # Expose Vaultwarden to your private Tailscale network via HTTPS.
  systemd.services.tailscale-serve-vaultwarden = {
    description = "Expose Vaultwarden over Tailscale HTTPS";
    after = ["tailscaled.service" "vaultwarden.service"];
    wants = ["tailscaled.service" "vaultwarden.service"];
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${pkgs.tailscale}/bin/tailscale serve --yes --https=443 http://127.0.0.1:${toString vaultwardenPort}";
      ExecStop = "${pkgs.tailscale}/bin/tailscale serve --https=443 off";
    };
  };
}
