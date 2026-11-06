{inputs, ...}: {
  flake.modules.homeManager.claude-code = {pkgs, ...}: let
    # Plugins linked under skills/ do not get CLAUDE_PLUGIN_ROOT, which their hook
    # scripts need to find themselves, so the hooks are registered here with the
    # plugin path written into each command. The script may include arguments.
    pluginHook = plugin: script: {
      type = "command";
      command = "CLAUDE_PLUGIN_ROOT=${plugin} ${pkgs.nodejs}/bin/node ${plugin}/${script}";
    };
  in {
    programs.claude-code = {
      enable = true;
      enableMcpIntegration = true;
      package = inputs.claude-code-nix.packages.${pkgs.stdenv.hostPlatform.system}.default;

      plugins = {
        ponytail = inputs.ponytail-plugin;
        caveman = inputs.caveman-plugin;
        context7 = inputs.context7-plugin + "/plugins/claude/context7";
      };

      skills = {
        context7-mcp = inputs.context7-plugin + "/plugins/codex/context7/skills/context7-mcp";
        andrej-karpathy-skills = ./../skills/andrej-karpathy-skills.md;
      };

      settings.hooks = {
        SessionStart = [
          {
            hooks = [
              (pluginHook inputs.ponytail-plugin "hooks/ponytail-activate.js")
              (pluginHook inputs.caveman-plugin "src/hooks/caveman-activate.js")
            ];
          }
        ];
        SubagentStart = [
          {
            hooks = [
              (pluginHook inputs.ponytail-plugin "hooks/ponytail-subagent.js")
              (pluginHook inputs.caveman-plugin "src/hooks/caveman-activate.js --subagent")
            ];
          }
        ];
        UserPromptSubmit = [
          {
            hooks = [
              (pluginHook inputs.ponytail-plugin "hooks/ponytail-mode-tracker.js")
              (pluginHook inputs.caveman-plugin "src/hooks/caveman-mode-tracker.js")
            ];
          }
        ];
      };
    };
  };
}
