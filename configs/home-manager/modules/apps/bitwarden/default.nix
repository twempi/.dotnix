{
  flake.modules.homeManager.bitwarden = {pkgs, ...}: {
    home.packages = with pkgs; [bitwarden-desktop];
  };
}
