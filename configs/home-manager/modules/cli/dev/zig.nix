{
  flake.modules.homeManager.dev = {pkgs, ...}: {
    home.packages = [
      pkgs.zig
    ];
  };
}
