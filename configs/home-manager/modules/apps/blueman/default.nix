{
  flake.modules.homeManager.blueman = {pkgs, ...}: {
    home.packages = with pkgs; [
      blueman
    ];
  };
}
