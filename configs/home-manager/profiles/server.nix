{...}: {
  imports = [
    ../base.nix
    ../modules/cli/core-packages
    ../modules/cli/docker
    ../modules/cli/bat
    ../modules/cli/btop
    ../modules/cli/fish
    ../modules/cli/ssh
    ../modules/cli/tmux
    ../modules/cli/git/server.nix
    ../modules/theme/ohmyposh
    ../modules/editors/neovim
    ../modules/apps/syncthing
    ../modules/cli/yazi
  ];
}
