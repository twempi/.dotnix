{
  flake.modules.homeManager.lazygit = {
    stylix.targets.lazygit.enable = true;

    programs.lazygit = {
      enable = true;
    };
  };
}
