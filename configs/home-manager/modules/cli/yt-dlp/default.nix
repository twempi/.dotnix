{pkgs, ...}: {
  programs.yt-dlp = {
    enable = true;
    package = pkgs.yt-dlp;
    settings = {
      paths = "~/Downloads";
      output = "%(title)s [%(id)s].%(ext)s";
      format = "bv*+ba/b";
      "merge-output-format" = "mp4";
    };
  };
}
