{config, ...}: let
  inherit (config.flake.modules) homeManager;
in {
  # Feature modules for the desktop profile (desktop and g14).
  flake.modules.homeManager.profile-desktop = {
    imports = with homeManager; [
      base

      # Other
      theme
      latex
      typst
      neovim

      # Themes
      switcher
      fontconfig
      ohmyposh

      # Window Managers
      hyprland
      sway

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
      agent-reach
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
      pomodoro

      # Desktop
      audio
      wayland-tools
      gnome-apps
      networking
      bluetooth
      # Sway imports the Amane shell; Hyprland uses Noctalia.
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
      sioyek
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
      nemo
      thunar
      feh
      bitwarden
    ];
  };
}
