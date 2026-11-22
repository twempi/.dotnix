{
  flake.modules.homeManager.ohmyposh = {
    pkgs,
    config,
    ...
  }: {
    programs.oh-my-posh = {
      enable = true;
      enableFishIntegration = true;
      enableZshIntegration = true;
      enableBashIntegration = true;

      settings =
        builtins.fromTOML (builtins.readFile ./config.toml)
        // {
          # Base16 accents of the active stylix scheme, for `p:<name>` colors
          # such as DEVSHELL_NAME = "C++/p:orange".
          palette = with config.lib.stylix.colors.withHashtag; {
            red = base08;
            orange = base09;
            yellow = base0A;
            green = base0B;
            cyan = base0C;
            blue = base0D;
            magenta = base0E;
            brown = base0F;
          };
        };
    };
  };
}
