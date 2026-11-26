{
  flake.modules.homeManager.spotatui = {pkgs, ...}: {
    home.packages = with pkgs; [
      spotatui
    ];
  };
}
