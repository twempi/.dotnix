{
  programs.fastfetch = {
    enable = true;
    settings = {
      logo = {
        source = "${./ascii/hello-kitty.txt}";
        # type = "kitty";
        type = "file";
        height = 10;
        padding = {
          top = 1;
          bottom = 0;
          right = 2;
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
          color = {
            user = "32";
            at = "90";
            host = "32";
          };
          key = " ";
          keyColor = "32";
        }
        {
          type = "os";
          key = " ";
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
          type = "wm";
          format = "{} ({3})";
          key = " ";
          keyColor = "33";
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
