{pkgs, ...}: {
  imports = [
    ../base.nix

    ../modules/theme
    ../modules/theme/fontconfig
    ../modules/theme/ohmyposh

    ../modules/desktop/defaults
    ../modules/desktop/gnome-keyring
    ../modules/desktop/noctalia
    ../modules/desktop/windowmanagers/hyprland

    ../modules/terminals/kitty

    ../modules/cli/bat
    ../modules/cli/btop
    ../modules/cli/fish
    ../modules/cli/git/server.nix
    ../modules/cli/ssh
    ../modules/cli/tmux
    ../modules/cli/yazi
    ../modules/cli/yt-dlp

    ../modules/apps/mpv
    ../modules/apps/spicetify
    ../modules/apps/syncthing
  ];

  home.packages = with pkgs; [
    home-manager
    brightnessctl
    curl
    eza
    fd
    file
    jq
    libnotify
    ncdu
    pavucontrol
    playerctl
    ripgrep
    tree
    unzip
    wget
    wl-clipboard
    xdg-utils
    zip
  ];
}
