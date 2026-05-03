{
  services.suwayomi-server = {
    enable = true;

    openFirewall = true;

    settings.server = {
      extensionRepos = [
        "https://raw.githubusercontent.com/keiyoushi/extensions/repo/index.min.json"
      ];

      downloadAsCbz = true;

      # Local source folder.
      # localSourcePath = "/var/lib/suwayomi-server/local";
    };
  };
}
