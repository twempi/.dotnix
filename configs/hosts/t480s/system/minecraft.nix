{
  pkgs,
  inputs,
  ...
}: {
  imports = [inputs.nix-minecraft.nixosModules.minecraft-servers];
  nixpkgs.overlays = [inputs.nix-minecraft.overlay];

  environment.systemPackages = with pkgs; [
    jdk8
    jdk21
  ];

  services.minecraft-servers = {
    enable = true;
    eula = true;
    openFirewall = true;
    servers = {
      fabric = {
        enable = false;
        openFirewall = true;
        jvmOpts = "-Xmx12G -Xms2G";
        package = pkgs.fabricServers.fabric-1_21_11.override {
          loaderVersion = "0.18.4";
        };

        symlinks = {
          mods = ./mods;
        };

        operators = {
          blangebob = "4a3ae14d-62aa-4b6e-b381-0ebb0708569a";
        };

        serverProperties = {
          server-port = 12345;
          difficulty = 3;
          gamemode = 1;
          max-players = 20;
          motd = "fabric";
        };
      };

      vanilla = {
        enable = true;
        autoStart = true;
        openFirewall = true;
        jvmOpts = "-Xmx6G -Xms2G";
        package = pkgs.vanillaServers.vanilla-1_21_10;

        operators = {
          blangebob = {
            uuid = "4a3ae14d-62aa-4b6e-b381-0ebb0708569a";
            level = 3;
            bypassesPlayerLimit = true;
          };
        };

        serverProperties = {
          server-port = 25565;
          difficulty = 3;
          gamemode = 1;
          max-players = 20;
          motd = "NASA Server";
          spawn-protection = 0;
          level-name = "world";
        };

        files = {
          "world/datapacks/double_shulker.zip" = ./. + "/minecraft/datapacks/double shulker shells v1.3.15 (MC 1.21-1.21.11).zip";

          "world/datapacks/multiplayer_sleep.zip" = ./. + "/minecraft/datapacks/multiplayer sleep v2.6.15 (MC 1.21-1.21.11).zip";

          "world/datapacks/player_head_drop.zip" = ./. + "/minecraft/datapacks/player head drops v1.1.15 (MC 1.21-1.21.11).zip";

          "world/datapacks/unlock_all_recipe.zip" = ./. + "/minecraft/datapacks/unlock all recipes v2.0.16 (MC 1.21-1.21.11).zip";

          "server-icon.png" = ./. + "/minecraft/server-icon.png";
        };
      };
    };
  };
}
