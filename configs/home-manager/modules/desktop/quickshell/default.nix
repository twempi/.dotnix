{
  config,
  inputs,
  lib,
  pkgs,
  system,
  ...
}:
let
  quickshellPackage = inputs.quickshell.packages.${system}.default;
  qsConfigs = import ./nix/configs.nix {
    inherit config pkgs;
  };
  helpers = import ./nix/helpers.nix {
    inherit lib pkgs quickshellPackage;
  };
  services = import ./nix/services.nix {
    inherit config helpers lib pkgs quickshellPackage;
  };
in {
  home.packages = helpers.packages;

  home.activation.qsWallpaperThumbnailCache = lib.hm.dag.entryAfter ["writeBoundary"] ''
    ${lib.getExe helpers.qsWallpaperCache} warm || true
  '';

  programs.quickshell = {
    enable = true;
    package = quickshellPackage;
    configs = qsConfigs.configs;
    systemd.enable = false;
  };

  systemd.user.services = services;
}
