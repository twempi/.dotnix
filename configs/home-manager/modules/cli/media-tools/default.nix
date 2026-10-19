{
  flake.modules.homeManager.media-tools = {pkgs, ...}: {
    home.packages = with pkgs; [
      ffmpeg
      ghostscript
      mermaid-cli
      tectonic-unwrapped
    ];
  };
}
