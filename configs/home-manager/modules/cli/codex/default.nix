{
  inputs,
  pkgs,
  ...
}: {
  programs.codex = {
    enable = true;
    package = inputs.codex-cli-nix.packages.${pkgs.stdenv.hostPlatform.system}.default;

    plugins = [
      inputs.ponytail-plugin
      (inputs.context7-plugin + "/plugins/codex/context7")
    ];
  };
}
