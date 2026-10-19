{
  flake.modules.homeManager.ios = {pkgs, ...}: {
    home.packages = with pkgs; [
      libimobiledevice
      ifuse
    ];
  };
}
