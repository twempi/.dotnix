{
  imports = [
    # ./desktop
    # ./laptop

    ./de/niri.nix
    ./de/sway.nix
    ./de/hyprland.nix
    # ./de/mango.nix

    ./modules/packages.nix
    ./modules/bootloader.nix
    ./modules/wayland.nix
    ./modules/audio.nix
    ./modules/shell.nix
    ./modules/user.nix
    ./modules/gnomeapps.nix
    ./modules/homelab.nix
    ./modules/games.nix
    ./modules/services.nix
    ./modules/chromium.nix
    ./modules/seahorse.nix
    ./modules/localsend.nix
    ./modules/minecraft.nix
    ./modules/dns-over-tls.nix
    ./modules/usbmuxd.nix
    ./modules/nh.nix
    ./modules/syncthing.nix
  ];
}
