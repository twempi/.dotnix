{config, ...}: {
  programs.fastfetch = {
    enable = true;

    settings = {
      logo = {
        source = "${./ascii/hello-kitty.txt}";
        type = "file";

        color = {
          "1" = "35";
        };

        padding = {
          top = 2;
          right = 6;
        };
      };

      display = {
        separator = " •  ";
      };

      modules = [
        "break"
        "break"

        {
          type = "title";
          key = " ";
          keyWidth = 10;
          keyColor = "35";

          color = {
            user = "35";
            at = "90";
            host = "35";
          };
        }

        "break"

        {
          type = "os";
          key = " ";
          keyColor = "35";
        }

        {
          type = "host";
          key = "🖥 ";
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
          keyColor = "35";
        }

        {
          type = "terminal";
          key = " ";
          keyColor = "35";
        }

        {
          type = "wm";
          key = " ";
          keyColor = "33";
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
          keyColor = "91";
        }

        {
          type = "memory";
          key = "🎟 ";
          keyColor = "36";
        }

        "break"

        {
          type = "colors";
          symbol = "circle";
        }

        "break"
        "break"
      ];
    };
  };
}
