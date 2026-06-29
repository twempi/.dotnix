{pkgs, ...}: let
  dotnixClipboard = pkgs.callPackage ./package.nix {};
in {
  home.packages = with pkgs; [
    dotnixClipboard
    wl-clipboard
    xclip
    xsel
  ];
}
