{
  services.suwayomi-server = {
    enable = true;

    openFirewall = true;

    settings.server = {
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
