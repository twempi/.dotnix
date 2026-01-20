{
  pkgs,
  lib,
  inputs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    # Wayland
    hyprpicker
    grim
    grimblast
    slurp
    hyprlock
    swaynotificationcenter
    waybar
    swww

    gnome-keyring
    cliphist
    wl-clipboard

    xdg-utils
    xdg-desktop-portal
    xdg-desktop-portal-gtk
    xdg-desktop-portal-hyprland

    # Desktop apps
    obs-studio
    pavucontrol
    anki-bin
    bleachbit
    gimp
    obsidian
    mpv
    qbittorrent
    brave
    rofi
    nautilus
    networkmanagerapplet
    switcheroo
    localsend
    openrgb
    zoom-us
    seahorse
    gnome-clocks
    zathura

    # CLI
    brightnessctl
    ani-cli
    bluetui
    oh-my-posh
    eza
    yazi
    neovim
    bluez
    bat
    btop
    curl
    fastfetch
    ffmpeg
    file
    fzf
    git
    killall
    docker
    lazygit
    ncdu
    ntfs3g
    progress
    ripgrep
    tmux
    tree
    unzip
    watch
    wget
    zip
    lua
    gh
    sl
    chntpw
    spotdl
    nix-prefetch-git
    yt-dlp
    usbmuxd
    upower
    tlp
    libnotify
    imagemagick
    tectonic-unwrapped
    ghostscript
    mermaid-cli
    ventoy-full-gtk
    wlsunset
    blueman
    inputs.ltspice.packages.${pkgs.system}.default
    pipx
    gearlever

    # Python
    (python313.withPackages (ps: [
      ps.pywal
      ps.watchdog
    ]))

    # LibreOffice
    libreoffice
    hunspell
    hunspellDicts.en_US

    # Other
    gcc
    clang
    zig
    typst
    home-manager
  ];

  nixpkgs.config.permittedInsecurePackages = [
    "ventoy-gtk3-1.1.07"
  ];

  fonts.packages =
    (builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts))
    ++ (with pkgs; [
      vista-fonts
      dina-font
      fira-code
      fira-code-symbols
      liberation_ttf
      mplus-outline-fonts.githubRelease
      mplus-outline-fonts.githubRelease
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      proggyfonts
      corefonts
    ]);
}
