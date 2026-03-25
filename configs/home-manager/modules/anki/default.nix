{pkgs, ...}: {
  stylix.targets.anki.enable = true;

  programs.anki.profiles.edward = {
    enable = true;
    sync = {
      autoSync = true;
      keyFile = "/home/edward/.dotnix/home-manager/modules/anki/syncKey";
      username = "edwarddan72@gmail.com";
    };

    addons = with pkgs; [
      ankiAddons.review-heatmap
    ];
  };
}
