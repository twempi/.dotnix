{
  flake.modules.homeManager.mcomix = {pkgs, ...}: {
    home.packages = with pkgs; [
      mcomix
    ];
  };
}
