{pkgs, ...}: {
  stylix.targets.anki.enable = true;

  programs.anki = {
    enable = true;
    profiles.edward.sync = {
      autoSync = true;
      keyFile = "${./syncKey}";
      username = "edwarddan72@gmail.com";
    };

    addons = with pkgs; [
      ankiAddons.review-heatmap
    ];
  };
}
