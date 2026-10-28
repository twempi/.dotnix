{
  flake.modules.homeManager.pomodoro = {pkgs, ...}: {
    home.packages = with pkgs; [
      pom
      tomato-c
    ];
  };
}
