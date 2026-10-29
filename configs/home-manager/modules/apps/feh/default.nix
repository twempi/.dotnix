{
  flake.modules.homeManager.feh = {pkgs, ...}: {
    home.packages = [
      pkgs.feh
    ];

    stylix.targets.feh.enable = true;

    programs.feh = {
      enable = true;
    };
  };
}
