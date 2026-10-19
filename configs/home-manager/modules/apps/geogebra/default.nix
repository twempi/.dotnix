{
  flake.modules.homeManager.geogebra = {pkgs, ...}: {
    home.packages = with pkgs; [
      geogebra
    ];
  };
}
