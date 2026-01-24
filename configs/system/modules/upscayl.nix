{ pkgs, ... }:
{
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "upscayl-x11" ''
      unset GBM_BACKEND __GLX_VENDOR_LIBRARY_NAME LIBVA_DRIVER_NAME
      exec ${pkgs.upscayl}/bin/upscayl --ozone-platform=x11 "$@"
    '')
  ];
}
