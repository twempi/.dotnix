{
  flake.modules.homeManager.artcraft = {pkgs, ...}: {
    home.packages = with pkgs; [
      photocraft
      vectorcraft
      pdfcraft
    ];
  };
}
