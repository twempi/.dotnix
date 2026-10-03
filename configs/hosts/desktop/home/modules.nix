{lib, pkgs, ...}: let
  arduinoIde = pkgs.writeShellScriptBin "arduino-ide" ''
    # Arduino IDE 2.3.10 segfaults in this host's Wayland/NVIDIA session.
    exec ${pkgs.uwsm}/bin/uwsm app -t scope ${pkgs.coreutils}/bin/env \
      ELECTRON_OZONE_PLATFORM_HINT=x11 \
      NIXOS_OZONE_WL=0 \
      ${pkgs.arduino-ide}/bin/arduino-ide "$@"
  '';
in {
  imports = [
    ./modules/windowmanagers/hyprland
    ./modules/windowmanagers/sway
    ./modules/windowmanagers/mango
    ./modules/fish
    ./modules/graphics-tools
  ];

  home.packages = [
    (lib.meta.hiPrio arduinoIde)
  ];
}
