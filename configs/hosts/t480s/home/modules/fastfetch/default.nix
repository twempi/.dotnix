{
  programs.fastfetch = {
    enable = true;

    settings = {
      logo = {
        source = "${./ascii/otter.txt}";
        type = "file";

        # These are terminal ANSI colors used by ${c1}, ${c2}, etc.
        color = {
          "1" = "33"; # yellow
          "2" = "35"; # magenta
          "3" = "36"; # cyan
          "4" = "91"; # bright red
          "5" = "32"; # green
          "6" = "34"; # blue
          "7" = "95"; # bright magenta
          "8" = "90"; # gray
        };

        padding = {
          top = 1;
          bottom = 0;
          right = 4;
          left = 1;
        };
      };

      display = {
        separator = " •  ";
      };

      modules = [
        "break"
        "break"
        "break"

        {
          type = "title";
          key = " ";
          keyColor = "33";

          color = {
            user = "33";
            at = "90";
            host = "33";
          };
        }

        {
          type = "os";
          key = " ";
          keyColor = "33";
        }

        {
          type = "host";
          key = "󰌢 ";
          keyColor = "35";
        }

        {
          type = "kernel";
          key = " ";
          keyColor = "91";
        }

        {
          type = "uptime";
          key = "󰅐 ";
          keyColor = "36";
        }

        {
          type = "shell";
          key = ">_";
          keyColor = "33";
        }

        {
          type = "terminal";
          key = " ";
          keyColor = "35";
        }

        {
          type = "wm";
          key = " ";
          keyColor = "36";
          format = "{} ({3})";
        }

        {
          type = "cpu";
          key = "󰍛 ";
          keyColor = "91";
        }

        {
          type = "gpu";
          key = "󰢮 ";
          keyColor = "95";
        }

        {
          type = "memory";
          key = "󰘚 ";
          keyColor = "36";
        }

        "break"

        {
          type = "colors";
          symbol = "circle";
        }
      ];
    };
  };
}
