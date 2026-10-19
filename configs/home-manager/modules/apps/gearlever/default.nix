{
  flake.modules.homeManager.gearlever = {pkgs, ...}: {
    home.packages = with pkgs; [
      gearlever
    ];
  };
}
