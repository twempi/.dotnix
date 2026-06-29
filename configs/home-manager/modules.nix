{
  imports = [
    # Other
    ./modules/theme
    ./modules/editors/latex
    ./modules/editors/typst
    ./modules/editors/neovim
    ./modules/editors/vscodium

    # Themes
    ./modules/theme/matugen
    ./modules/theme/fontconfig
    ./modules/theme/ohmyposh

    # Window Managers
    ./modules/desktop/windowmanagers/hyprland
    ./modules/desktop/windowmanagers/sway
    ./modules/desktop/windowmanagers/mango

    # Terminal
    ./modules/terminals/ghostty
    ./modules/terminals/kitty
    ./modules/terminals/alacritty
    ./modules/terminals/foot

    # Cli
    ./modules/cli/core-packages
    ./modules/cli/dev
    ./modules/cli/docker
    ./modules/cli/media-tools
    ./modules/cli/ios
    ./modules/cli/ani-cli
    ./modules/cli/codex
    ./modules/cli/tmux
    ./modules/cli/fish
    ./modules/cli/ssh
    ./modules/cli/yt-dlp
    ./modules/cli/git
    ./modules/cli/yazi
    ./modules/cli/fastfetch
    ./modules/cli/btop
    ./modules/cli/bat
    ./modules/cli/lazygit
    ./modules/cli/gowall
    ./modules/cli/cyberdrop-dl

    # Desktop
    ./modules/desktop/audio
    ./modules/desktop/wayland-tools
    ./modules/desktop/gnome-apps
    ./modules/desktop/networking
    ./modules/desktop/bluetooth
    # Superseded by Noctalia for Hyprland, Sway, and Mango.
    # ./modules/desktop/waybar
    # Superseded by Noctalia for notifications and control center.
    # ./modules/desktop/swaync
    # Superseded by Noctalia for launcher, wallpaper, power, clipboard, emoji, and GPU picker.
    # ./modules/desktop/rofi
    ./modules/desktop/defaults
    ./modules/desktop/gnome-keyring
    # ./modules/desktop/dms
    ./modules/desktop/noctalia

    # Apps
    ./modules/apps/obs-studio
    ./modules/apps/pavucontrol
    ./modules/apps/bleachbit
    ./modules/apps/gimp
    ./modules/apps/qbittorrent
    ./modules/apps/zoom
    ./modules/apps/gnome-clocks
    ./modules/apps/gearlever
    ./modules/apps/iloader
    ./modules/apps/geogebra
    ./modules/apps/telegram
    ./modules/apps/blueman
    ./modules/apps/pdfarranger
    ./modules/apps/libreoffice
    ./modules/apps/ltspice
    ./modules/apps/minecraft
    ./modules/apps/localsend
    ./modules/apps/seahorse
    ./modules/apps/switcheroo
    ./modules/apps/nixcord
    ./modules/apps/spicetify
    ./modules/apps/mpv
    ./modules/apps/zathura
    ./modules/apps/anki
    ./modules/apps/chromium
    ./modules/apps/zen-browser
    ./modules/apps/upscayl
    ./modules/apps/syncthing
    # ./modules/apps/sioyek
    ./modules/apps/sunsetr
    ./modules/apps/helium
    ./modules/apps/obsidian
    ./modules/apps/rars
    ./modules/apps/blanket
  ];
}
