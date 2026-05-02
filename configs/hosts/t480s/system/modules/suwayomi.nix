{
  services.suwayomi-server = {
    enable = true;

    # Only needed if you want to access it from another device on your LAN.
    # For localhost only, you can leave this false or remove it.
    openFirewall = false;

    settings.server = {
      # Local-only access. Safer default.
      ip = "127.0.0.1";

      # Use whichever port is currently working for you.
      # If you opened it at localhost:8080, keep 8080.
      port = 8080;

      # Keiyoushi extension repo, same ecosystem used by Mihon/Tachimanga.
      extensionRepos = [
        "https://raw.githubusercontent.com/keiyoushi/extensions/repo/index.min.json"
      ];

      # Optional: download chapters as CBZ files.
      downloadAsCbz = true;

      # Optional: local source folder.
      # You can put local manga files here later if you want.
      # localSourcePath = "/var/lib/suwayomi-server/local";
    };
  };
}
