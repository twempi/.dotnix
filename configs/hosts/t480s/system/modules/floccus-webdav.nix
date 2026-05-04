{
  services.webdav-server-rs = {
    enable = true;

    settings = {
      server.listen = ["127.0.0.1:4918"];

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

  systemd.tmpfiles.rules = [
    "d /var/lib/floccus-webdav 0750 root webdav -"
    "d /var/lib/floccus-webdav/data 0750 webdav webdav -"
    "f /var/lib/floccus-webdav/htpasswd 0640 root webdav -"
  ];
}
