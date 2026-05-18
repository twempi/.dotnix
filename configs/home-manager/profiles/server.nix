{pkgs, ...}: {
  imports = [
    ../base.nix
    ../modules/cli/bat
    ../modules/cli/btop
    ../modules/cli/fish
    ../modules/cli/ssh
    ../modules/cli/tmux
    ../modules/cli/git/server.nix
    ../modules/theme/ohmyposh
    ../modules/editors/nixcats
    ../modules/apps/syncthing
    ../modules/cli/yazi
  ];

  home.packages = with pkgs; [
    home-manager
    curl
    wget
    ripgrep
    fd
    eza
    tree
    unzip
    zip
    jq
    ncdu
    file
  ];
}
