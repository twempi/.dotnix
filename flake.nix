{
  description = "edwards flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    nixos-hardware.url = "github:NixOS/nixos-hardware";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixCats = {
      url = "github:BirdeeHub/nixCats-nvim";
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

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mango = {
      url = "github:mangowm/mango";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-minecraft = {
      url = "github:Infinidoge/nix-minecraft";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ltspice.url = "git+https://codeberg.org/pilonsi/flake-ltspice";

    quickshell = {
      url = "git+https://git.outfoxxed.me/quickshell/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dms = {
      url = "github:AvengeMedia/DankMaterialShell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    nixpkgs,
    home-manager,
    stylix,
    nixCats,
    nixcord,
    spicetify-nix,
    bunny-yazi,
    zen-browser,
    niri,
    nix-minecraft,
    ltspice,
    dms,
    quickshell,
    mango,
    ...
  }: let
    system = "x86_64-linux";

    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
  in {
    nixosConfigurations = {
      desktop = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./configs/hosts/desktop/default.nix
          home-manager.nixosModules.home-manager
          stylix.nixosModules.stylix
        ];

        specialArgs = {
          inherit inputs system;
        };
      };

      t480s = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./configs/hosts/t480s/default.nix
          home-manager.nixosModules.home-manager
          stylix.nixosModules.stylix
        ];

        specialArgs = {
          inherit inputs system;
        };
      };

      g14 = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./configs/hosts/g14/default.nix
          home-manager.nixosModules.home-manager
          stylix.nixosModules.stylix
        ];

        specialArgs = {
          inherit inputs system;
        };
      };
    };

    homeConfigurations = {
      edward-desktop = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {
          inherit inputs system;
          hostname = "desktop";
        };
        modules = [
          ./configs/home-manager/home.nix
          ./configs/hosts/desktop/home/modules.nix
          stylix.homeModules.stylix
          inputs.spicetify-nix.homeManagerModules.default
          niri.homeModules.config
          niri.homeModules.stylix
        ];
      };

      edward-g14 = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {
          inherit inputs system;
          hostname = "g14";
        };
        modules = [
          ./configs/home-manager/home.nix
          ./configs/hosts/g14/home/modules.nix
          stylix.homeModules.stylix
          inputs.spicetify-nix.homeManagerModules.default
          niri.homeModules.config
          niri.homeModules.stylix
        ];
      };

      edward-t480s = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {
          inherit inputs system;
          hostname = "t480s";
        };
        modules = [
          ./configs/home-manager/home.nix
          ./configs/hosts/t480s/home/modules.nix
          stylix.homeModules.stylix
          inputs.spicetify-nix.homeManagerModules.default
          niri.homeModules.config
          niri.homeModules.stylix
        ];
      };
    };
  };
}
