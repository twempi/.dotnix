{
  flake.modules.homeManager.vscodium = {pkgs, ...}: {
    home.packages = with pkgs; [
      vscodium
    ];
  };
}
