{
  flake.modules.homeManager.anki = {pkgs, ...}: {
    stylix.targets.anki.enable = true;

    programs.anki = {
      enable = true;
      profiles.edward.sync = {
        autoSync = true;
        keyFile = "/run/secrets/anki_sync_key";
        username = "edwarddan72@gmail.com";
      };

      addons = with pkgs; [
        ankiAddons.review-heatmap
        ankiAddons.anki-connect
      ];
    };
  };
}
