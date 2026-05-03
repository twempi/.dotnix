{
  pkgs,
  config,
  lib,
  ...
}: {
  home.packages = with pkgs; [
    texliveFull
    latexrun
    texlivePackages.latexmk
  ];
}
