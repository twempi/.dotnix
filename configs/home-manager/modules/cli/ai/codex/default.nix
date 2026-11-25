{inputs, ...}: {
  flake.modules.homeManager.codex = {pkgs, ...}: {
    programs.codex = {
      enable = true;
      enableMcpIntegration = true;
      package = inputs.codex-cli-nix.packages.${pkgs.stdenv.hostPlatform.system}.default;

      plugins = [
        inputs.ponytail-plugin
        (inputs.context7-plugin + "/plugins/codex/context7")
      ];
      skills = {
        andrej-karpathy-skills = ./../skills/andrej-karpathy-skills.md;
      };
    };
  };

  # The ponytail plugin's own hooks never run: Codex skips them until they are trusted
  # in /hooks, and that trust is saved to ~/.codex/config.toml, which Home Manager keeps
  # read-only. Hooks in /etc/codex are trusted by policy, so the same hooks go there.
  flake.modules.nixos.codex = {pkgs, ...}: let
    # Codex runs hook commands through the login shell (fish), so the environment is set
    # in a script. ponytail detects Codex by PLUGIN_DATA; this is the data directory Codex
    # gives the ponytail@home-manager plugin.
    ponytailHook = script: {
      type = "command";
      command = "${pkgs.writeShellScript "codex-${script}" ''
        export CLAUDE_PLUGIN_ROOT=${inputs.ponytail-plugin}
        export PLUGIN_DATA="''${CODEX_HOME:-$HOME/.codex}/plugins/data/ponytail-home-manager"
        exec ${pkgs.nodejs}/bin/node ${inputs.ponytail-plugin}/hooks/${script}.js
      ''}";
      timeout = 15;
    };
  in {
    environment.etc."codex/hooks.json".text = builtins.toJSON {
      hooks = {
        SessionStart = [
          {
            matcher = "startup|resume|clear|compact";
            hooks = [(ponytailHook "ponytail-activate")];
          }
        ];
        SubagentStart = [{hooks = [(ponytailHook "ponytail-subagent")];}];
        UserPromptSubmit = [{hooks = [(ponytailHook "ponytail-mode-tracker")];}];
      };
    };
  };
}
