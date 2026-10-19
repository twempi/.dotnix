{config, ...}: let
  inherit (config.flake.modules) homeManager;
in {
  flake.modules.homeManager.profile-server = {
    imports = with homeManager; [
      base
      core-packages
      docker
      bat
      btop
      fish
      ssh
      clipboard
      tmux
      git-server
      ohmyposh
      neovim
      syncthing
      yazi
    ];
  };
}
