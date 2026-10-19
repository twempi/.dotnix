{
  flake.modules.homeManager.ltspice = {pkgs, ...}: {
    home.packages = with pkgs; [
      ltspice
    ];
  };
}
