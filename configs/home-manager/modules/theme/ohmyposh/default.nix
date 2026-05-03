{ pkgs, config, ...}: {
  programs.oh-my-posh = {
    enable = true;
    enableFishIntegration = true;
    enableZshIntegration = true;
    enableBashIntegration = true;

    settings = builtins.fromTOML (builtins.readFile ./config.toml);
    };
}
