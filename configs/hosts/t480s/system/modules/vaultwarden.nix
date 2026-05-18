{
  config,
  pkgs,
  ...
}: let
  vaultwardenInternalPort = 8222;
  vaultwardenExternalPort = 8222;

  # Depending on how Tailscale Services exposes this, this may become:
  # https://vaultwarden.tailae03d0.ts.net:8222
  vaultwardenUrl = "https://vaultwarden.tailae03d0.ts.net:${toString vaultwardenExternalPort}";
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
      ROCKET_PORT = vaultwardenInternalPort;
      ROCKET_LOG = "critical";

      SHOW_PASSWORD_HINT = false;
      INVITATIONS_ALLOWED = true;
    };
  };

  services.tailscale.serve.services.vaultwarden = {
    endpoints = {
      "tcp:${toString vaultwardenExternalPort}" = "http://127.0.0.1:${toString vaultwardenInternalPort}";
    };

    advertised = true;
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/vaultwarden 0750 vaultwarden vaultwarden -"
    "d /var/backup/vaultwarden 0750 vaultwarden vaultwarden -"
  ];
}
