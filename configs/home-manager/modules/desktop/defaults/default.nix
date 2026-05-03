{pkgs, ...}: {
  ############################
  # Environment variables
  ############################
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";

    # BROWSER = "${pkgs.brave}/bin/brave";
    # DEFAULT_BROWSER = "${pkgs.brave}/bin/brave";
    BROWSER = "zen-beta";
    DEFAULT_BROWSER = "zen-beta";
  };

  ############################
  # XDG MIME associations
  ############################
  xdg.mimeApps = {
    enable = true;

    defaultApplications = {
      # Web / URLs
      # "text/html" = ["brave-browser.desktop"];
      # "application/xhtml+xml" = ["brave-browser.desktop"];
      # "x-scheme-handler/http" = ["brave-browser.desktop"];
      # "x-scheme-handler/https" = ["brave-browser.desktop"];

      # Images (EOG)
      "image/png" = ["org.gnome.eog.desktop"];
      "image/jpeg" = ["org.gnome.eog.desktop"];
      "image/jpg" = ["org.gnome.eog.desktop"];
      "image/gif" = ["org.gnome.eog.desktop"];
      "image/bmp" = ["org.gnome.eog.desktop"];
      "image/svg+xml" = ["org.gnome.eog.desktop"];

      # Video / Audio (mpv)
      "video/mp4" = ["mpv.desktop"];
      "video/x-matroska" = ["mpv.desktop"];
      "video/webm" = ["mpv.desktop"];
      "audio/mpeg" = ["mpv.desktop"];
      "audio/ogg" = ["mpv.desktop"];
      "audio/wav" = ["mpv.desktop"];

      # File manager
      "inode/directory" = ["org.gnome.Nautilus.desktop"];

      # Documents
      "application/pdf" = ["org.pwmt.zathura.desktop"];

      # Zoom
      "x-scheme-handler/zoommtg" = ["zoom-us.desktop"];
      "application/x-zoom" = ["zoom-us.desktop"];
    };
  };
}
