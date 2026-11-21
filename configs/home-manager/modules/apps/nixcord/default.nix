{inputs, ...}: {
  flake.modules.homeManager.nixcord = {
    imports = [
      inputs.nixcord.homeModules.nixcord
    ];

    # stylix.targets.nixcord.enable = true;
    programs.nixcord = {
      enable = true;
      discord.enable = false;
      vesktop.enable = true;

      config = {
        frameless = true;
        autoUpdate = true;
        autoUpdateNotification = true;
      };
    };
  };
}
