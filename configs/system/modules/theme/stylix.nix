{
  imports = [
    ../../../stylix/theme.nix
  ];

  stylix.homeManagerIntegration = {
    autoImport = true;
    followSystem = true;
  };
}
