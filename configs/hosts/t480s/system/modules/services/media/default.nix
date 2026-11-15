{
  # Shared by Jellyfin, Sonarr, and qBittorrent so they can read and write each other's files.
  flake.modules.nixos.t480s-media = {
    users.groups.media = {};
    users.users.edward.extraGroups = ["media"];
  };
}
