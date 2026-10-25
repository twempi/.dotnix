{
  flake.modules.homeManager.niri = {pkgs, ...}: {
    programs.niri.package = pkgs.niri;
    stylix.targets.niri.enable = true;
  };
}
