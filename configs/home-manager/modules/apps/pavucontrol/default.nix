{
  flake.modules.homeManager.pavucontrol = {pkgs, ...}: {
    home.packages = with pkgs; [
      pavucontrol
    ];
  };
}
