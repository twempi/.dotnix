{pkgs, ...}: {
  home.packages = with pkgs; [
    home-manager
    curl
    wget
    fd
    file
    fzf
    jq
    killall
    ncdu
    progress
    ripgrep
    tree
    unzip
    watch
    zip
    sl
    chntpw
    nix-prefetch-git
    trash-cli
    upower
    eza
  ];
}
