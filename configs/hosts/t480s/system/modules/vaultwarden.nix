{
  config,
  pkgs,
  ...
}: let
  vaultwardenUrl = "https://t480s.tailae03d0.ts.net";
  vaultwardenPort = 8222;
in {
  services.vaultwarden = {
    enable = true;
    dbBackend = "sqlite";

    environmentFile = "/var/lib/vaultwarden/vaultwarden.env";
    backupDir = "/var/backup/vaultwarden";

    config = {
      DOMAIN = vaultwardenUrl;

      SIGNUPS_ALLOWED = false;

      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = vaultwardenPort;
      ROCKET_LOG = "critical";

      SHOW_PASSWORD_HINT = false;
      INVITATIONS_ALLOWED = true;
    };
  };

  services.tailscale.enable = true;

  systemd.tmpfiles.rules = [
    "d /var/lib/vaultwarden 0750 vaultwarden vaultwarden -"
    "d /var/backup/vaultwarden 0750 vaultwarden vaultwarden -"
  ];
}
