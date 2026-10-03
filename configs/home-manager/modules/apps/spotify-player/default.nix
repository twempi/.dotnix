{
  pkgs,
  inputs,
  ...
}: {
  stylix.targets.spotify-player.colors.enable = true;

  programs.spotify-player = {
    enable = true;
    package = inputs.spotify-player.defaultPackage.${pkgs.stdenv.hostPlatform.system};
  };
}
