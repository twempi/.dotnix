{
  flake.modules.homeManager.networking = {pkgs, ...}: {
    home.packages = with pkgs; [
      networkmanagerapplet
    ];
  };
}
