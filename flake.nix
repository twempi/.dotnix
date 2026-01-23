{
  description = "edwards flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    nixos-hardware.url = "github:NixOS/nixos-hardware";

    home-manager = {
      url = "github:nix-community/home-manager";
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
    };

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # elephant.url = "github:abenz1267/elephant";
    #
    # walker = {
    #   url = "github:abenz1267/walker";
    #   inputs.elephant.follows = "elephant";
    # };

    nix-minecraft = {
      url = "github:Infinidoge/nix-minecraft";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ltspice.url = "git+https://codeberg.org/pilonsi/flake-ltspice";
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
    # walker,
    nix-minecraft,
    ltspice,
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
          # inputs.mango.nixosModules.mango
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
          # inputs.mango.nixosModules.mango
        ];

        specialArgs = {
          inherit inputs system;
        };
      };
    };

    homeConfigurations = {
      edward = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = {
          inherit inputs system;
        };
        modules = [
          ./configs/home-manager/home.nix
          stylix.homeModules.stylix
          inputs.spicetify-nix.homeManagerModules.default
          niri.homeModules.config
          niri.homeModules.stylix

          # inputs.mango.hmModules.mango
        ];
      };
    };
  };
}
