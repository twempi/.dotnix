{
  inputs,
  pkgs,
  system,
}:
pkgs.writeShellApplication {
  name = "g14-refresh-rate";

  runtimeInputs = [
    pkgs.upower
    pkgs.jq
    pkgs.gnugrep
    pkgs.gawk
    pkgs.coreutils
    pkgs.sway
    inputs.hyprland.packages.${system}.hyprland
    pkgs.dbus
    pkgs.systemd
  ];

  text = builtins.readFile ./refresh-rate.sh;
}
