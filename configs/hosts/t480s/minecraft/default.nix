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
    enable = false;
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
        jvmOpts = "-Xmx4G -Xms2G";
        package = pkgs.vanillaServers.vanilla-1_21_10;

        operators = {
          blangebob = "4a3ae14d-62aa-4b6e-b381-0ebb0708569a";
        };

        symlinks = {
          # "world/datapacks" = ./datapacks;
        };

        serverProperties = {
          server-port = 25565;
          difficulty = 3;
          gamemode = 1;
          max-players = 20;
          motd = "vanilla new";
          # level-name = "world";
        };
      };
    };
  };
}
