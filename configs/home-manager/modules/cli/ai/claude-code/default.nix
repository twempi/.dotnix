{
  inputs,
  pkgs,
  ...
}: {
  programs.claude-code = {
    enable = true;
    enableMcpIntegration = true;
    package = inputs.claude-code-nix.packages.${pkgs.stdenv.hostPlatform.system}.default;

    plugins = {
      ponytail = inputs.ponytail-plugin;
      context7 = inputs.context7-plugin + "/plugins/claude/context7";
    };

    skills = {
      context7-mcp = inputs.context7-plugin + "/plugins/codex/context7/skills/context7-mcp";
      andrej-karpathy-skills = ./../skills/andrej-karpathy-skills.md;
    };
  };
}
