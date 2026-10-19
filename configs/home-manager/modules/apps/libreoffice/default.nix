{
  flake.modules.homeManager.libreoffice = {pkgs, ...}: {
    home.packages = with pkgs; [
      libreoffice
      hunspell
      hunspellDicts.en_US
    ];
  };
}
