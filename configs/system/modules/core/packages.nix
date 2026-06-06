{
  pkgs,
  pkgsStable,
  lib,
  inputs,
  ...
}: {
  nixpkgs.overlays = [
    (final: prev: {
      iloader = prev.callPackage ../../pkgs/iloader/default.nix {};
      handy = prev.callPackage ../../pkgs/handy/default.nix {};
    })
  ];

  environment.systemPackages = with pkgs; [
    # Wayland
    hyprpicker
    grim
    grimblast
    slurp
    hyprlock
    swaynotificationcenter
    waybar
    awww

    gnome-keyring
    cliphist
    wl-clipboard

    xdg-utils

    # Desktop apps
    obs-studio
    pavucontrol
    anki-bin
    bleachbit
    gimp
    obsidian
    qbittorrent
    brave
    rofi
    nautilus
    networkmanagerapplet
    switcheroo
    localsend
    zoom-us
    seahorse
    gnome-clocks
    zathura
    gearlever
    upscayl
    iloader
    vscodium
    geogebra
    telegram-desktop
    blueman
    pdfarranger

    # CLI
    brightnessctl
    bluetui
    impala
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
    nix-prefetch-git
    usbmuxd
    ani-cli
    upower
    tlp
    libnotify
    imagemagick
    tectonic-unwrapped
    ghostscript
    mermaid-cli
    ltspice
    trash-cli
    inputs.codex-cli-nix.packages.${pkgs.stdenv.hostPlatform.system}.default

    # Python
    (python313.withPackages (ps: [
      ps.pywal
      ps.watchdog
    ]))
    pkgsStable.python3
    pkgsStable.pipx

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
