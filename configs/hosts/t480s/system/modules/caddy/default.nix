{
  config,
  pkgs,
  ...
}: let
  mkStylixStartpage = import ./startpage/lib/mkStylixStartpage.nix;
  siteRoot = mkStylixStartpage {
    inherit pkgs;
    source = ./startpage;
    colors = config.lib.stylix.colors;
    fontFamily = config.stylix.fonts.monospace.name;
    sansFontFamily = config.stylix.fonts.sansSerif.name;
  };
in {
  services.tailscale.permitCertUid = "caddy";

  services.caddy = {
    enable = true;
    virtualHosts."t480s.tailae03d0.ts.net".extraConfig = ''
      handle_path /floccus-webdav/* {
        reverse_proxy 127.0.0.1:4918
      }

      handle /api/settings {
        reverse_proxy 127.0.0.1:4919
      }

      handle /settings.json {
        header Cache-Control "no-store, max-age=0"
        header Access-Control-Allow-Origin "*"
        root * /var/lib/startpage
        file_server
      }

      handle {
        header Cache-Control "no-store, max-age=0"
        root * ${siteRoot}
        file_server
      }
    '';
  };

  systemd.services.startpage-settings-api = {
    description = "Startpage central settings API";
    after = ["network.target"];
    wantedBy = ["multi-user.target"];
    environment = {
      STARTPAGE_SETTINGS_FILE = "/var/lib/startpage/settings.json";
      STARTPAGE_SETTINGS_HOST = "127.0.0.1";
      STARTPAGE_SETTINGS_PORT = "4919";
      STARTPAGE_SETTINGS_ORIGIN = "https://t480s.tailae03d0.ts.net";
    };
    serviceConfig = {
      Type = "simple";
      User = "edward";
      Group = "caddy";
      ExecStart = "${pkgs.python3}/bin/python ${./startpage/settings-api.py}";
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ReadWritePaths = ["/var/lib/startpage"];
      ProtectHome = true;
      Restart = "on-failure";
    };
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/startpage 0750 edward caddy -"
    "C /var/lib/startpage/settings.json 0640 edward caddy - ${./startpage/settings.default.json}"
  ];

  system.activationScripts.migrateStartpageNixSearchSettings.text = ''
    ${pkgs.python3}/bin/python <<'PY'
    import json
    import os
    import sys
    import tempfile
    from pathlib import Path
    import grp
    import pwd

    settings_path = Path("/var/lib/startpage/settings.json")
    old_bookmark_href = "https://mynixos.com/"
    new_bookmark_href = "https://nixsearch.thekoppe.com/"
    old_bookmark_title = "nix pakgs"
    new_bookmark_title = "nix pkgs"
    old_default_ns_tag = {
        "prefix": "ns",
        "url": "https://nixsearch.thekoppe.com/?q=$q",
    }
    entertainment_bookmarks = [
        {
            "href": "http://t480s.tailae03d0.ts.net:8096/web/",
            "title": "jellyfin",
            "category": "tv",
        },
        {
            "href": "https://open.spotify.com/",
            "title": "spotify",
            "category": "tv",
        },
    ]

    def write_settings(settings):
        data = json.dumps(settings, indent=2, ensure_ascii=False) + "\n"
        fd, temp_path = tempfile.mkstemp(
            prefix=f".{settings_path.name}.",
            suffix=".tmp",
            dir=str(settings_path.parent),
            text=True,
        )

        try:
            with os.fdopen(fd, "w", encoding="utf-8") as fh:
                fh.write(data)
                fh.flush()
                os.fsync(fh.fileno())

            uid = pwd.getpwnam("edward").pw_uid
            gid = grp.getgrnam("caddy").gr_gid
            os.chown(temp_path, uid, gid)
            os.chmod(temp_path, 0o640)
            os.replace(temp_path, settings_path)

            dir_fd = os.open(settings_path.parent, os.O_RDONLY)
            try:
                os.fsync(dir_fd)
            finally:
                os.close(dir_fd)
        except Exception:
            try:
                os.unlink(temp_path)
            except FileNotFoundError:
                pass
            raise

    def main():
        if not settings_path.exists():
            return

        settings = json.loads(settings_path.read_text(encoding="utf-8"))
        changed = False

        bookmarks = settings.get("bookmarks")
        if isinstance(bookmarks, list):
            for bookmark in bookmarks:
                if not isinstance(bookmark, dict):
                    continue
                if bookmark.get("href") == old_bookmark_href or bookmark.get("title") == old_bookmark_title:
                    bookmark["href"] = new_bookmark_href
                    bookmark["title"] = new_bookmark_title
                    changed = True

            existing_hrefs = {
                bookmark.get("href")
                for bookmark in bookmarks
                if isinstance(bookmark, dict)
            }
            for bookmark in entertainment_bookmarks:
                if bookmark["href"] not in existing_hrefs:
                    bookmarks.append(bookmark)
                    existing_hrefs.add(bookmark["href"])
                    changed = True

        custom_tags = settings.get("customTags")
        if isinstance(custom_tags, list):
            filtered_tags = [
                tag for tag in custom_tags
                if not (
                    isinstance(tag, dict)
                    and tag.get("prefix") == old_default_ns_tag["prefix"]
                    and tag.get("url") == old_default_ns_tag["url"]
                )
            ]
            if len(filtered_tags) != len(custom_tags):
                settings["customTags"] = filtered_tags
                changed = True

        if changed:
            write_settings(settings)

    try:
        main()
    except Exception as err:
        print(f"warning: could not migrate startpage Nix Search settings: {err}", file=sys.stderr)
    PY
  '';

  networking.firewall.allowedTCPPorts = [80 443];
}
