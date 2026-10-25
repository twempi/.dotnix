{
  flake.modules.homeManager.dev = {pkgs, ...}: {
    home.packages = [
      pkgs.arduino-cli
    ];
  };
}
