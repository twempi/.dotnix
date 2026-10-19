{
  flake.modules.homeManager.switcheroo = {pkgs, ...}: {
    home.packages = with pkgs; [
      switcheroo
    ];
  };
}
