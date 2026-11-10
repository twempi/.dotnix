{
  flake.modules.homeManager.awww = {pkgs, ...}: {
    home.packages = with pkgs; [
      awww
    ];
  };
}
