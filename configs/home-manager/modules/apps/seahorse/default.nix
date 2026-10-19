{
  flake.modules.homeManager.seahorse = {pkgs, ...}: {
    home.packages = with pkgs; [
      seahorse
    ];
  };
}
