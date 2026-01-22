{
  pkgs,
  inputs,
  ...
}: let
  pref-by-location-plugin = pkgs.fetchFromGitHub {
    owner = "boydaihungst";
    repo = "pref-by-location.yazi";
    rev = "882e75297a2a07cd892e383800d493ad484f7eec";
    sha256 = "17k4w0k9s40g1mkz887lj2c1dvz4q2rlflnsrsxb618r5dqd48z0";
  };
in {
  stylix.targets.yazi.enable = true;

  programs.yazi = {
    enable = true;

    enableZshIntegration = true;
    enableBashIntegration = true;
    enableFishIntegration = true;

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
        title_format = "Yazi: {cwd}";
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
        sixel_fraction = 15;
        ueberzug_scale = 1;
        ueberzug_offset = [0 0 0 0];
      };

      opener = {
        edit = [
          {
            run = ''$EDITOR "$@"'';
            block = true;
            for = "unix";
          }
        ];
      };
    };

    keymap = {
      mgr.prepend_keymap = [
        {
          run = "plugin bunny";
          on = [";"];
          desc = "Start bunny.yazi";
        }

        {
          run = ["hidden toggle" "plugin pref-by-location -- save"];
          on = ["."];
          desc = "Toggle the visibility of hidden files";
        }

        # Linemode
        {
          on = ["m" "s"];
          run = ["linemode size" "plugin pref-by-location -- save"];
          desc = "Linemode: size";
        }
        {
          on = ["m" "p"];
          run = ["linemode permissions" "plugin pref-by-location -- save"];
          desc = "Linemode: permissions";
        }
        {
          on = ["m" "b"];
          run = ["linemode btime" "plugin pref-by-location -- save"];
          desc = "Linemode: btime";
        }
        {
          on = ["m" "m"];
          run = ["linemode mtime" "plugin pref-by-location -- save"];
          desc = "Linemode: mtime";
        }
        {
          on = ["m" "o"];
          run = ["linemode owner" "plugin pref-by-location -- save"];
          desc = "Linemode: owner";
        }
        {
          on = ["m" "n"];
          run = ["linemode none" "plugin pref-by-location -- save"];
          desc = "Linemode: none";
        }
        # Custom size_and_mtime linemode
        # { on = [ "u" "S" ]; run = [ "linemode size_and_mtime" "plugin pref-by-location -- save" ]; desc = "Show Size and Modified time"; }

        # Sorting / pref-by-location controls
        {
          on = ["," "t"];
          run = "plugin pref-by-location -- toggle";
          desc = "Toggle auto-save preferences";
        }
        {
          on = ["," "d"];
          run = "plugin pref-by-location -- disable";
          desc = "Disable auto-save preferences";
        }
        {
          on = ["," "R"];
          run = ["plugin pref-by-location -- reset"];
          desc = "Reset preference of cwd";
        }
        {
          on = ["," "m"];
          run = ["sort mtime --reverse=no" "linemode mtime" "plugin pref-by-location -- save"];
          desc = "Sort by modified time";
        }
        {
          on = ["," "M"];
          run = ["sort mtime --reverse" "linemode mtime" "plugin pref-by-location -- save"];
          desc = "Sort by modified time (reverse)";
        }
        {
          on = ["," "b"];
          run = ["sort btime --reverse=no" "linemode btime" "plugin pref-by-location -- save"];
          desc = "Sort by birth time";
        }
        {
          on = ["," "B"];
          run = ["sort btime --reverse" "linemode btime" "plugin pref-by-location -- save"];
          desc = "Sort by birth time (reverse)";
        }
        {
          on = ["," "e"];
          run = ["sort extension --reverse=no" "plugin pref-by-location -- save"];
          desc = "Sort by extension";
        }
        {
          on = ["," "E"];
          run = ["sort extension --reverse" "plugin pref-by-location -- save"];
          desc = "Sort by extension (reverse)";
        }
        {
          on = ["," "a"];
          run = ["sort alphabetical --reverse=no" "plugin pref-by-location -- save"];
          desc = "Sort alphabetically";
        }
        {
          on = ["," "A"];
          run = ["sort alphabetical --reverse" "plugin pref-by-location -- save"];
          desc = "Sort alphabetically (reverse)";
        }
        {
          on = ["," "n"];
          run = ["sort natural --reverse=no" "plugin pref-by-location -- save"];
          desc = "Sort naturally";
        }
        {
          on = ["," "N"];
          run = ["sort natural --reverse" "plugin pref-by-location -- save"];
          desc = "Sort naturally (reverse)";
        }
        # --sensitive=no or --sensitive
        # { on = [ "," "N" ]; run = [ "sort natural --reverse=no --sensitive" "plugin pref-by-location -- save" ];    desc = "Sort naturally"; }
        {
          on = ["," "s"];
          run = ["sort size --reverse=no" "linemode size" "plugin pref-by-location -- save"];
          desc = "Sort by size";
        }
        {
          on = ["," "S"];
          run = ["sort size --reverse" "linemode size" "plugin pref-by-location -- save"];
          desc = "Sort by size (reverse)";
        }
        {
          on = ["," "r"];
          run = ["sort random --reverse=no" "plugin pref-by-location -- save"];
          desc = "Sort randomly";
        }
      ];
    };

    plugins = {
      "full-border" = pkgs.yaziPlugins.full-border;
      "bunny" = "${inputs.bunny-yazi}";
      "pref-by-location" = pref-by-location-plugin;
    };

    initLua = ''
      require("full-border"):setup()
      require("pref-by-location"):setup({})

      require("bunny"):setup({
        hops = {
          { key = "/", path = "/" },
          { key = "t", path = "/tmp" },
          { key = "h", path = "~", desc = "Home" },
          { key = "d", path = "~/Downloads/", desc = "Downloads" },
          { key = "D", path = "~/Documents", desc = "Documents" },
          { key = "c", path = "~/.config", desc = "Config" },
          { key = "n", path = "~/.dotnix", desc = "Nix Config" },
          { key = "p", path = "~/Pictures", desc = "Pictures" },
          { key = { "l", "s" }, path = "~/.local/share", desc = "Local share" },
          { key = { "l", "b" }, path = "~/.local/bin", desc = "Local bin" },
          { key = { "l", "t" }, path = "~/.local/state", desc = "Local state" },
          { key = { "s", "p" }, path = "/mnt/Storage/Pictures", desc = "Storage Pictures" },
        },
        desc_strategy = "path",
        ephemeral = true,
        tabs = true,
        notify = false,
        fuzzy_cmd = "fzf",
      })
    '';
  };
}
