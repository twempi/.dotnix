{
  description = "edwards flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.11";

    nixos-hardware.url = "github:NixOS/nixos-hardware";

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

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
    };

    hyprland.url = "github:hyprwm/Hyprland";

    mangowm = {
      url = "github:mangowm/mango";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-minecraft = {
      url = "github:Infinidoge/nix-minecraft";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    dms = {
      url = "github:AvengeMedia/DankMaterialShell";
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
      url = "gitlab:ntgn/helium-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    codex-cli-nix = {
      url = "github:sadjow/codex-cli-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    t3code = {
      url = "github:rodeyseijkens/t3code-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    corecycler = {
      url = "github:Daaboulex/linux-corecycler";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    minimal-grub-theme = {
      url = "github:twempi/minimal-grub-theme";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    librepods = {
      url = "github:kavishdevar/librepods/linux/rust";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    luasnip-latex-snippets-nvim = {
      url = "github:twempi/luasnip-latex-snippets.nvim";
      flake = false;
    };
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

    localPkgs = import ./configs/system/pkgs {inherit pkgs;};

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
    packages.${system} = localPkgs.packages;

    apps.${system} = localPkgs.apps;

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
