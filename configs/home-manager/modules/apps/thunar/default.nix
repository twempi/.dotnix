{
  flake.modules.homeManager.thunar = {pkgs, ...}: {
    home.packages = with pkgs; [
      thunar
    ];
  };
}
