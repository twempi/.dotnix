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

    mangowm = {
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

    iloaderPackage = pkgs.callPackage ./configs/system/pkgs/iloader/default.nix {};

    updateIloader = pkgs.writeShellApplication {
      name = "update-iloader";
      runtimeInputs = [
        pkgs.curl
        pkgs.git
        pkgs.jq
        pkgs.nix
        pkgs.perl
      ];
      text = ''
        repo_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
        if [[ -z "$repo_root" ]]; then
          echo "error: run this from inside the dotnix git repository" >&2
          exit 1
        fi

        script="$repo_root/configs/system/pkgs/iloader/update.sh"
        if [[ ! -f "$script" ]]; then
          echo "error: updater script not found: $script" >&2
          exit 1
        fi

        exec "$script" "$@"
      '';
    };

    specialArgsFor = hostname: {
      inherit inputs system hostname;
    };

    commonNixosModules = [
      home-manager.nixosModules.home-manager
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
    packages.${system} = rec {
      iloader = iloaderPackage;
      default = iloader;
    };

    apps.${system}.update-iloader = {
      type = "app";
      program = "${updateIloader}/bin/update-iloader";
    };

    nixosConfigurations = {
      desktop = mkNixosHost "desktop" [
        inputs.t3code.nixosModules.default
      ];

      t480s = mkNixosHost "t480s" [];

      g14 = mkNixosHost "g14" [
        inputs.t3code.nixosModules.default
      ];
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
