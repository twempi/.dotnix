{
  flake.modules.homeManager.handy = {pkgs, ...}: {
    home.packages = with pkgs; [
      handy
      wtype
      xdotool
    ];
  };
}
