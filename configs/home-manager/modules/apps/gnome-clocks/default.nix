{
  flake.modules.homeManager.gnome-clocks = {pkgs, ...}: {
    home.packages = with pkgs; [
      gnome-clocks
    ];
  };
}
