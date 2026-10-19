{
  flake.modules.homeManager.bluetooth = {pkgs, ...}: {
    home.packages = with pkgs; [
      bluez
      bluetui
    ];
  };
}
