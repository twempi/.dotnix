{
  imports = [
    ../modules/core/packages.nix
    ../modules/core/home-manager.nix
    ../modules/core/bootloader.nix
    ../modules/core/shell.nix
    ../modules/core/user.nix
    ../modules/core/nh.nix

    ../modules/networking/dns-over-tls.nix
    ../modules/networking/usbmuxd.nix
    ../modules/networking/localsend.nix

    ../modules/services/homelab.nix
    ../modules/services/services.nix

    ../modules/desktop/wayland.nix
    ../modules/desktop/audio.nix
    ../modules/desktop/gnomeapps.nix
    ../modules/desktop/chromium.nix
    ../modules/desktop/seahorse.nix
    ../modules/desktop/login-manager.nix
    ../modules/desktop/niri.nix
    ../modules/desktop/sway.nix
    ../modules/desktop/hyprland.nix
    ../modules/desktop/mango.nix

    ../modules/apps/appimage.nix
    ../modules/apps/helium.nix
    ../modules/apps/librepods.nix
  ];
}
