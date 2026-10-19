{config, ...}: let
  inherit (config.flake.modules) homeManager;
in {
  # Feature modules for the desktop profile (desktop and g14).
  flake.modules.homeManager.profile-desktop = {
    imports = with homeManager; [
      # Other
      theme
      latex
      typst
      neovim
      vscodium

      # Themes
      matugen
      switcher
      fontconfig
      ohmyposh

      # Window Managers
      hyprland
      sway
      niri

      # Terminal
      ghostty
      kitty
      alacritty
      foot

      # Cli
      core-packages
      dev
      docker
      media-tools
      ios
      ani-cli
      codex
      claude-code
      rea
      mcp
      clipboard
      tmux
      fish
      ssh
      yt-dlp
      git
      yazi
      fastfetch
      btop
      bat
      lazygit
      gowall
      cyberdrop-dl
      pi

      # Desktop
      audio
      wayland-tools
      gnome-apps
      networking
      bluetooth
      # Superseded by Noctalia for Hyprland, Sway, and Niri.
      # waybar
      # Superseded by Noctalia for notifications and control center.
      # swaync
      # Superseded by Noctalia for launcher, wallpaper, power, clipboard, emoji, and GPU picker.
      # rofi
      defaults
      gnome-keyring
      # dms
      noctalia
      webcam

      # Apps
      arduino-ide
      obs-studio
      pavucontrol
      bleachbit
      gimp
      qbittorrent
      zoom
      gnome-clocks
      gearlever
      handy
      iloader
      geogebra
      telegram
      blueman
      pdfarranger
      libreoffice
      ltspice
      minecraft
      localsend
      seahorse
      switcheroo
      nixcord
      spicetify
      mpv
      zathura
      anki
      chromium
      # zen-browser
      upscayl
      syncthing
      # sioyek
      sunsetr
      helium
      obsidian
      rars
      blanket
      mcomix
      # distrobox
      t3code
      spotify-player
      fritzing
      artcraft
    ];
  };
}
