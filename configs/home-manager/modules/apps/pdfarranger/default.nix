{
  flake.modules.homeManager.pdfarranger = {pkgs, ...}: {
    home.packages = with pkgs; [
      pdfarranger
    ];
  };
}
