{config, ...}: {
  programs.fastfetch = {
    enable = true;

    settings = {
      "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";

      logo = {
        source = "${./ascii/hello-kitty.txt}";

        # Uses your terminal theme's ANSI colors
        color = {
          "1" = "magenta";
        };

        padding = {
          top = 2;
          right = 6;
        };
      };

      display = {
        separator = " ";
      };

      modules = [
        "break"
        "break"

        {
          type = "title";
          keyWidth = 10;
          color = "bright_magenta";
        }

        "break"

        {
          type = "os";
          key = " ";
          keyColor = "magenta";
          color = "white";
        }

        {
          type = "host";
          key = "🖥 ";
          keyColor = "magenta";
          color = "white";
        }

        {
          type = "shell";
          key = ">_";
          keyColor = "magenta";
          color = "white";
        }

        {
          type = "terminal";
          key = " ";
          keyColor = "magenta";
          color = "white";
        }

        {
          type = "wm";
          key = " ";
          keyColor = "magenta";
          color = "white";
        }

        {
          type = "cpu";
          key = "󰍛 ";
          keyColor = "magenta";
          color = "white";
        }

        {
          type = "gpu";
          key = "󰢮 ";
          keyColor = "magenta";
          color = "white";
        }

        {
          type = "memory";
          key = "🎟 ";
          keyColor = "magenta";
          color = "white";
        }

        "break"
        "break"
        "break"
      ];
    };
  };
}
