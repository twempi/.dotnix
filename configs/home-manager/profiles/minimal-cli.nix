{pkgs, ...}: {
  imports = [
    ../base.nix
    ../modules/cli/ssh
    ../modules/cli/tmux
    ../modules/cli
    ../modules/cli/git/server.nix
  ];

  home.packages = with pkgs; [
    home-manager
    neovim
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
