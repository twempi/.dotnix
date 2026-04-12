{pkgs, ...}: {
  programs.yt-dlp = {
    enable = true;
    settings = {
      # Put downloads in ~/Downloads
      paths = "~/Downloads";

      # Nice default filename
      output = "%(title)s [%(id)s].%(ext)s";

      # Prefer best video+audio, and merge when needed
      format = "bv*+ba/b";

      # Prefer mp4 as the final container when possible
      "merge-output-format" = "mp4";
    };
  };

  # Recommended so merging/remuxing works properly
  home.packages = with pkgs; [
    ffmpeg
  ];
}
