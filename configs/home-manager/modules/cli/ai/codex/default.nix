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
}
