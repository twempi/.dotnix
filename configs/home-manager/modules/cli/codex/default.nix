{
  hostname,
  inputs,
  lib,
  pkgs,
  ...
}: let
  rea = pkgs.buildNpmPackage {
    pname = "rea-agents";
    version = "6.0.0";
    src = inputs.rea-plugin;
    npmDepsHash = "sha256-ninOfE/wyfYkdV5cd6zrl5mdzN6WCDzE2giWnaNjWGk=";
    nodejs = pkgs.nodejs_24;
    nativeBuildInputs = [pkgs.autoPatchelfHook];
    buildInputs = [pkgs.stdenv.cc.cc.lib];
    env.HUSKY = "0";
    # The Nix build already runs the build that prepack would repeat.
    npmPackFlags = ["--ignore-scripts"];
  };
in {
  home.packages = lib.optionals (hostname == "desktop") [rea];

  programs.codex = {
    enable = true;
    package = inputs.codex-cli-nix.packages.${pkgs.stdenv.hostPlatform.system}.default;

    plugins = [
      inputs.ponytail-plugin
      (inputs.context7-plugin + "/plugins/codex/context7")
    ];

    settings = lib.optionalAttrs (hostname == "desktop") {
      mcp_servers.rea = {
        command = "${rea}/bin/rea";
        args = ["mcp"];
        startup_timeout_sec = 30;
      };
    };

    skills = lib.optionalAttrs (hostname == "desktop") {
      reverse-engineer-anything = "${rea}/lib/node_modules/rea-agents/skills/reverse-engineer-anything";
    };
  };
}
