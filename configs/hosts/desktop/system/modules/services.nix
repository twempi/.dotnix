# { config, pkgs, ... }: {
#   # OpenRGB
#   services.hardware.openrgb = {
#     enable = true; 
#     motherboard = "amd"; 
#     # startupProfile = "black";
#   };
#
#   systemd.user.services.openrgb-profile = {
#     description = "Apply OpenRGB profile at boot";
#     after = [ "graphical-session.target" ];
#     wants = [ "graphical-session.target" ];
#     partOf = [ "graphical-session.target" ];
#     wantedBy = [ "graphical-session.target" ];
#
#     serviceConfig = {
#       Type = "simple";
#       ExecStartPre = "${pkgs.coreutils}/bin/sleep 2";
#       ExecStart = "${pkgs.openrgb}/bin/openrgb --profile ~/.config/OpenRGB/black.orp";
#       Restart = "on-failure";
#       RestartSec = 2;
#       ConditionPathExists = "%h/.config/OpenRGB/black.orp";
#     };
#   };
# }

{ pkgs, lib, ... }:
let
  no-rgb = pkgs.writeScriptBin "no-rgb" ''
    #!/bin/sh
    NUM_DEVICES=$(${pkgs.openrgb}/bin/openrgb --noautoconnect --list-devices | grep -E '^[0-9]+: ' | wc -l)

    for i in $(seq 0 $(($NUM_DEVICES - 1))); do
      ${pkgs.openrgb}/bin/openrgb --noautoconnect --device $i --mode static --color 000000
    done
  '';
in {
  config = {
    services.udev.packages = [ pkgs.openrgb ];
    boot.kernelModules = [ "i2c-dev" ];
    hardware.i2c.enable = true;

    systemd.services.no-rgb = {
      description = "no-rgb";
      serviceConfig = {
        ExecStart = "${no-rgb}/bin/no-rgb";
        Type = "oneshot";
      };
      wantedBy = [ "multi-user.target" ];
    };
  };
}
