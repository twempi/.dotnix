{config, ...}: {
  flake.modules.homeManager.niri = {pkgs, ...}: {
    imports = [
      config.flake.modules.homeManager.amane
    ];

    programs.niri.package = pkgs.niri;
    stylix.targets.niri.enable = true;
  };
}
