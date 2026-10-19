{
  flake.modules.homeManager.ani-cli = {pkgs, ...}: {
    home.packages = with pkgs; [
      ani-cli
    ];
  };
}
