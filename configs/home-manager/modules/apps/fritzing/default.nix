{
  flake.modules.homeManager.fritzing = {pkgs, ...}: {
    home.packages = [
      pkgs.fritzing
    ];
  };
}
