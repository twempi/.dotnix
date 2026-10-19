{
  flake.modules.homeManager.localsend = {pkgs, ...}: {
    home.packages = with pkgs; [
      localsend
    ];
  };
}
