{
  flake.modules.homeManager.deepseek-harness = {pkgs, ...}: {
    home.packages = with pkgs; [
      deepseek-harness
    ];
  };
}
