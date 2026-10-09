{
  lib,
  pkgs,
  ...
}: let
  arduinoIde = pkgs.writeShellScriptBin "arduino-ide" ''
    # Use X11 to avoid the observed Arduino IDE 2.3.10 Wayland/NVIDIA crash.
    exec ${pkgs.uwsm}/bin/uwsm app -t scope ${pkgs.coreutils}/bin/env \
      ELECTRON_OZONE_PLATFORM_HINT=x11 \
      NIXOS_OZONE_WL=0 \
      ${pkgs.arduino-ide}/bin/arduino-ide "$@"
  '';
in {
  home.packages = [
    pkgs.arduino-ide
    (lib.meta.hiPrio arduinoIde)
  ];
}
