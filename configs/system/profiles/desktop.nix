{config, ...}: let
  inherit (config.flake.modules) nixos;
in {
  flake.modules.nixos.profile-desktop = {
    imports = with nixos; [
      fonts
      home-manager
      bootloader
      shell
      user
      nh
      env
      cachix
      optimizations
      insecure-packages

      dns-over-tls
      usbmuxd
      localsend

      homelab
      services

      wayland
      audio
      gnomeapps
      chromium
      seahorse
      login-manager
      printing
      sway
      hyprland
      niri

      anki
      appimage
      handy
      helium
      idescriptor
      bt-dualboot
    ];

    # Windows dual-boot keeps the hardware clock in local time.
    time.hardwareClockInLocalTime = true;
    hardware.enableAllFirmware = true;
  };
}
