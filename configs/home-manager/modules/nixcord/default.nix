{inputs, ...}: {
  imports = [
  inputs.nixcord.homeModules.nixcord
  ./theme.nix
  ];

  # stylix.targets.nixcord.enable = true;
  programs.nixcord = {
    enable = true;
    vesktop.enable = true;
    discord.vencord.enable = true;

    config = {
      frameless = true;
      autoUpdate = true;
      autoUpdateNotification = true;
      themeLinks = [
        "https://raw.githubusercontent.com/mafien0/system24/refs/heads/main/theme/flavors/system24-rose-pine.theme.css"
      ];
      # enabledThemes = ["matugen.css"];
      # enabledThemes = ["discord-colors.css"];

      plugins = {
        experiments.enable = true;
        callTimer.enable = true;
        fakeNitro.enable = true;
        friendsSince.enable = true;
        imageZoom = {
          enable = true;
          invertScroll = true;
          size = 150.0;
        };
        keepCurrentChannel.enable = true;
        mentionAvatars.enable = true;
        noF1.enable = true;
        petpet.enable = true;
        pictureInPicture.enable = true;
        whoReacted.enable = true;
        biggerStreamPreview.enable = true;
        ClearURLs.enable = true;
        fixImagesQuality.enable = true;
        fixSpotifyEmbeds = {
          enable = true;
          volume = 0.05;
        };
        fixYoutubeEmbeds.enable = true;
        forceOwnerCrown.enable = true;
        gameActivityToggle = {
          enable = true;
        };
        messageLogger.enable = true;
        openInApp.enable = true;
        showHiddenChannels.enable = true;
        silentTyping.enable = true;
        spotifyCrack = {
          enable = true;
          noSpotifyAutoPause = true;
        };
        youtubeAdblock.enable = true;
      };
    };
  };
}
