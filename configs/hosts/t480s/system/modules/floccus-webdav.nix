{
  flake.modules.nixos.t480s-floccus-webdav = {pkgs, ...}: let
    floccusPort = 4918;
  in {
    services.webdav-server-rs = {
      enable = true;

      settings = {
        server.listen = ["127.0.0.1:${toString floccusPort}"];

        accounts = {
          auth-type = "htpasswd.floccus";
          acct-type = "unix";
          realm = "Floccus WebDAV";
        };

        htpasswd.floccus.htpasswd = "/var/lib/floccus-webdav/htpasswd";

        location = [
          {
            route = ["/*path"];
            directory = "/var/lib/floccus-webdav/data";
            handler = "filesystem";
            methods = ["webdav-rw"];
            auth = "true";
            autoindex = false;
          }
        ];
      };
    };

    # Served at the root of its own hostname: WebDAV MOVE carries an absolute
    # Destination path, which breaks behind a stripped path prefix.
    systemd.services.tailscale-serve-floccus = import ./_tailscale-serve-service.nix {
      inherit pkgs;
      name = "floccus";
      description = "Expose Floccus WebDAV as a Tailscale Service";
      port = floccusPort;
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/floccus-webdav 0750 root webdav -"
      "d /var/lib/floccus-webdav/data 0750 webdav webdav -"
      "f /var/lib/floccus-webdav/htpasswd 0640 root webdav -"
    ];
  };
}
