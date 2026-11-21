{
  flake.modules.homeManager.yazi = {
    config,
    pkgs,
    ...
  }: let
    pdfViewer = "${pkgs.zathura}/bin/zathura";
    # pdfViewer = "${config.programs.sioyek.package}/bin/sioyek";
    videoPlayer = "${pkgs.mpv}/bin/mpv";
    imageViewer = "${pkgs.feh}/bin/feh";
  in {
    stylix.targets.yazi.enable = true;

    programs.yazi = {
      enable = true;

      enableZshIntegration = true;
      enableBashIntegration = true;
      enableFishIntegration = true;

      shellWrapperName = "y";

      settings = {
        mgr = {
          ratio = [1 4 3];
          sort_by = "alphabetical";
          sort_sensitive = false;
          sort_reverse = false;
          sort_dir_first = true;
          sort_translit = false;
          linemode = "none";
          show_hidden = true;
          show_symlink = true;
          scrolloff = 5;
          mouse_events = ["click" "scroll"];
        };

        preview = {
          wrap = "yes";
          tab_size = 2;
          max_width = 600;
          max_height = 900;
          cache_dir = "";
          image_delay = 30;
          image_filter = "triangle";
          image_quality = 90;
          ueberzug_scale = 1;
          ueberzug_offset = [0 0 0 0];
        };

        opener = {
          edit = [
            {
              run = ''$EDITOR %s'';
              block = true;
              desc = "$EDITOR";
              for = "unix";
            }
          ];

          pdf = [
            {
              run = ''${pdfViewer} %s'';
              orphan = true;
              desc = "Open PDF";
              for = "linux";
            }
          ];

          play = [
            {
              run = ''${videoPlayer} %s'';
              orphan = true;
              desc = "Play video";
              for = "linux";
            }
          ];
          image = [
            {
              run = ''${imageViewer} %s'';
              orphan = true;
              desc = "Open image";
              for = "linux";
            }
          ];
        };

        open = {
          prepend_rules = [
            {
              mime = "application/pdf";
              use = "pdf";
            }
            {
              mime = "video/*";
              use = "play";
            }
            {
              mime = "image/*";
              use = "image";
            }
          ];
        };
      };
    };
  };
}
