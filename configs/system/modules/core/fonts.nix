{
  pkgs,
  lib,
  ...
}: {
  fonts.packages =
    (builtins.filter lib.attrsets.isDerivation (builtins.attrValues pkgs.nerd-fonts))
    ++ (with pkgs; [
      vista-fonts
      dina-font
      fira-code
      fira-code-symbols
      liberation_ttf
      mplus-outline-fonts.githubRelease
      mplus-outline-fonts.githubRelease
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      proggyfonts
      corefonts
    ]);
}
