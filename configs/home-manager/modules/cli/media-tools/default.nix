{pkgs, ...}: {
  home.packages = with pkgs; [
    ffmpeg
    ghostscript
    mermaid-cli
    tectonic-unwrapped
  ];
}
