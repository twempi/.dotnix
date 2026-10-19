{
  flake.modules.homeManager.iloader = {pkgs, ...}: {
    home.packages = with pkgs; [
      iloader
    ];
  };
}
