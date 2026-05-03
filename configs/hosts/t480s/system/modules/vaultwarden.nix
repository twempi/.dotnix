{
  config,
  pkgs,
  ...
}: let
  domain = "vault.example.com"; # CHANGE ME
  port = 8222;
in {
  services.vaultwarden = {
    enable = true;

    # Default is sqlite, which is fine for personal/family use.
    dbBackend = "sqlite";

    # Keep secrets out of the Nix store.
    environmentFile = "/var/lib/vaultwarden/vaultwarden.env";

    # Optional built-in backup location.
    backupDir = "/var/backup/vaultwarden";

    config = {
      DOMAIN = "https://${domain}";

      # Safer default:
      # Temporarily set this to true for first account creation,
      # then switch it back to false and rebuild.
      SIGNUPS_ALLOWED = false;

      # Allow admin-created invitations.
      INVITATIONS_ALLOWED = true;

      # Only listen locally; Caddy will expose HTTPS.
      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = port;
      ROCKET_LOG = "critical";

      # Basic privacy/security preferences.
      SHOW_PASSWORD_HINT = false;

      # Optional: enable once SMTP is configured.
      # SMTP_HOST = "smtp.example.com";
      # SMTP_PORT = 587;
      # SMTP_SECURITY = "starttls";
      # SMTP_FROM = "vaultwarden@example.com";
      # SMTP_FROM_NAME = "Vaultwarden";
      # SMTP_USERNAME = "vaultwarden@example.com";
    };
  };

  services.caddy = {
    enable = true;
    email = "edwarddan72@gmail.com"; # CHANGE ME

    virtualHosts."${domain}".extraConfig = ''
      encode zstd gzip

      reverse_proxy 127.0.0.1:${toString port} {
        header_up X-Real-IP {remote_host}
      }
    '';
  };

  networking.firewall.allowedTCPPorts = [80 443];

  systemd.tmpfiles.rules = [
    "d /var/lib/vaultwarden 0750 vaultwarden vaultwarden -"
    "d /var/backup/vaultwarden 0750 vaultwarden vaultwarden -"
  ];
}
