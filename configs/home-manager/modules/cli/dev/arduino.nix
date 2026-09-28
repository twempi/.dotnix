{pkgs, ...}: {
  home.packages = [
    pkgs.arduino-cli
    pkgs.arduino-ide
    pkgs.arduino-language-server
  ];
}
