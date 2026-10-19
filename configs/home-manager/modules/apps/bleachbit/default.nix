{
  flake.modules.homeManager.bleachbit = {pkgs, ...}: {
    home.packages = with pkgs; [
      bleachbit
    ];
  };
}
