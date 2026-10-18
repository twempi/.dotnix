{
  description = "edwards flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-26.05";

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-hardware = {
      url = "github:NixOS/nixos-hardware";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixWrapperModules = {
      url = "github:BirdeeHub/nix-wrapper-modules";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixcord = {
      url = "github:FlameFlag/nixcord";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    bunny-yazi = {
      url = "github:stelcodes/bunny.yazi";
      flake = false;
    };

    hyprland.url = "github:hyprwm/Hyprland";

    niri.url = "github:sodiboo/niri-flake";

    nix-minecraft = {
      url = "github:Infinidoge/nix-minecraft";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    noctalia = {
      url = "github:noctalia-dev/noctalia-shell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    tt-schemes = {
      url = "github:tinted-theming/schemes";
      flake = false;
    };

    helium = {
      url = "github:oxcl/nix-flake-helium-browser";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    codex-cli-nix = {
      url = "github:sadjow/codex-cli-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    context7-plugin = {
      url = "github:upstash/context7";
      flake = false;
    };

    ponytail-plugin = {
      url = "github:DietrichGebert/ponytail";
      flake = false;
    };

    rea-plugin = {
      url = "github:morluto/rea/rea-agents-6.0.0";
      flake = false;
    };

    claude-code-nix = {
      url = "github:sadjow/claude-code-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pi = {
      url = "github:lukasl-dev/pi.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    spotify-player = {
      url = "github:aome510/spotify-player";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    artcraft = {
      url = "github:devitek/artcraft-nixos";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    twempi = {
      url = "github:twempi/nix-inputs";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    amane.url = "github:MystiaFin/amane";

    # comfyui-nix.url = "github:utensils/comfyui-nix";
  };

  outputs = inputs @ {
    nixpkgs,
    home-manager,
    ...
  }: let
    system = "x86_64-linux";

    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };

    pkgsStable = import inputs.nixpkgs-stable {
      inherit system;
      config.allowUnfree = true;
    };

    specialArgsFor = hostname: {
      inherit inputs system hostname pkgsStable;
    };

    commonNixosModules = [
      home-manager.nixosModules.home-manager
      inputs.sops-nix.nixosModules.sops
      inputs.stylix.nixosModules.stylix
    ];

    mkNixosHost = hostname: extraModules:
      nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = specialArgsFor hostname;
        modules =
          [
            (./configs/hosts + "/${hostname}/default.nix")
          ]
          ++ commonNixosModules
          ++ extraModules;
      };

    commonHomeModules = [
      inputs.stylix.homeModules.stylix
      ./configs/system/modules/theme/stylix.nix
    ];

    desktopHomeModules = [
      inputs.spicetify-nix.homeManagerModules.default
      inputs.niri.homeModules.config
      inputs.niri.homeModules.stylix
    ];

    mkHome = {
      hostname,
      profile,
      extraModules ? [],
    }:
      home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = specialArgsFor hostname;
        modules =
          [
            (./configs/home-manager/profiles + "/${profile}.nix")
            (./configs/hosts + "/${hostname}/home/modules.nix")
          ]
          ++ commonHomeModules
          ++ extraModules;
      };
  in {
    nixosConfigurations = {
      desktop = mkNixosHost "desktop" [];

      t480s = mkNixosHost "t480s" [];

      g14 = mkNixosHost "g14" [];
    };

    homeConfigurations = {
      edward-desktop = mkHome {
        hostname = "desktop";
        profile = "desktop";
        extraModules = desktopHomeModules;
      };

      edward-g14 = mkHome {
        hostname = "g14";
        profile = "desktop";
        extraModules = desktopHomeModules;
      };

      edward-t480s = mkHome {
        hostname = "t480s";
        profile = "server";
      };
    };
  };
}
