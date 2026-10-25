{
  flake.modules.homeManager.nemo = {pkgs, ...}: {
    home.packages = with pkgs; [
      nemo
    ];
  };
}
