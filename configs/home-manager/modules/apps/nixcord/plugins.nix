{
  flake.modules.homeManager.nixcord = {
    programs.nixcord.config.plugins = {
      experiments.enable = true;
      callTimer.enable = true;
      fakeNitro.enable = true;
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
      clearUrls.enable = true;
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
}
