{
  flake.modules.homeManager.yazi = {
    programs.yazi.keymap = {
      mgr.prepend_keymap = [
        {
          on = ["<Enter>"];
          run = "plugin smart-enter";
          desc = "Enter the child directory, or open the file";
        }

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
        {
          on = ["R" "b"];
          run = "plugin trash";
          desc = "Open Trash";
        }
        {
          on = ["c" "p"];
          run = "plugin convert -- --extension='png'";
          desc = "Convert selected files to PNG";
        }
        {
          on = ["c" "j"];
          run = "plugin convert -- --extension='jpg'";
          desc = "Convert selected files to JPG";
        }
        {
          on = ["c" "w"];
          run = "plugin convert -- --extension='webp'";
          desc = "Convert selected files to WebP";
        }
      ];
    };
  };
}
