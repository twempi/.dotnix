{
  description = "edwards flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-26.05";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    import-tree.url = "github:vic/import-tree";

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

    librepods = {
      url = "github:kavishdevar/librepods/linux/rust";
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

  # Every .nix file under ./configs is a flake-parts module, except paths
  # containing `/_` (helpers and hardware-configuration.nix files).
  outputs = inputs:
    inputs.flake-parts.lib.mkFlake {inherit inputs;} (inputs.import-tree ./configs);
}
