{inputs, ...}: {
  flake.modules.homeManager.rea = {pkgs, ...}: let
    # Upstream has no flake.nix; build from the pinned rea-plugin input.
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

    reaSkill = "${rea}/lib/node_modules/rea-agents/skills/reverse-engineer-anything";
  in {
    home.packages = [rea];

    programs.codex = {
      settings.mcp_servers.rea = {
        command = "${rea}/bin/rea";
        args = ["mcp"];
        startup_timeout_sec = 30;
      };
      skills.reverse-engineer-anything = reaSkill;
    };

    programs.claude-code = {
      mcpServers.rea = {
        command = "${rea}/bin/rea";
        args = ["mcp"];
      };
      skills.reverse-engineer-anything = reaSkill;
    };
  };
}
