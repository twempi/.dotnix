# {
#   programs.fastfetch = {
#     enable = true;
#     settings = {
#       logo = {
#         source = "${./ascii/hello-kitty.txt}";
#         # type = "kitty";
#         type = "file";
#         height = 10;
#         padding = {
#           top = 1;
#           bottom = 0;
#           right = 2;
#           left = 1;
#         };
#       };
#       display = {
#         separator = " •  ";
#       };
#       modules = [
#         "break"
#         "break"
#         "break"
#         {
#           type = "title";
#           color = {
#             user = "32";
#             at = "90";
#             host = "32";
#           };
#           key = " ";
#           keyColor = "32";
#         }
#         {
#           type = "os";
#           key = " ";
#           keyColor = "35";
#         }
#         {
#           type = "kernel";
#           key = " ";
#           keyColor = "91";
#         }
#         {
#           type = "uptime";
#           key = "󰅐 ";
#           keyColor = "36";
#         }
#         {
#           type = "wm";
#           format = "{} ({3})";
#           key = " ";
#           keyColor = "33";
#         }
#         "break"
#         {
#           type = "colors";
#           symbol = "circle";
#         }
#       ];
#     };
#   };
# }
{config, ...}: {
  programs.fastfetch = {
    enable = true;

    settings = {
      "$schema" = "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json";

      logo = {
        source = "${./ascii/hello-kitty.txt}";

        color = {
          "1" = "#C6B7FF";
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
          color = "#D8CCFF";
        }

        "break"

        {
          type = "os";
          key = " ";
          keyColor = "#B8A6FF";
          color = "#E6E0FF";
          format = "NixOS";
        }

        {
          type = "host";
          key = "🖥 ";
          keyColor = "#B8A6FF";
          color = "#E6E0FF";
          format = "Zeibook Air";
        }

        {
          type = "shell";
          format = "{}";
          key = ">_";
          keyColor = "#B8A6FF";
          color = "#E6E0FF";
        }

        {
          type = "terminal";
          key = " ";
          keyColor = "#B8A6FF";
          color = "#E6E0FF";
        }

        {
          type = "wm";
          format = "{} (wayland)";
          key = " ";
          keyColor = "#B8A6FF";
          color = "#E6E0FF";
        }

        {
          type = "cpu";
          key = "󰍛 ";
          keyColor = "#B8A6FF";
          color = "#E6E0FF";
          format = "intel(R) i7-5650U";
        }

        {
          type = "gpu";
          key = "󰢮 ";
          keyColor = "#B8A6FF";
          color = "#E6E0FF";
          format = "Intel(R) HD 6000";
        }

        {
          type = "memory";
          key = "🎟 ";
          keyColor = "#B8A6FF";
          color = "#E6E0FF";
          format = "{} {}";
        }

        "break"
        "break"
        "break"
      ];
    };
  };
}
