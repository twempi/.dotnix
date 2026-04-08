{pkgs, ...}: {
  stylix.targets.foot = {
    enable = true;
    colors.enable = true;
    fonts = {
      enable = true;
      override = {
        monospace = {
          name = "Geist Mono";
          package = pkgs.geist-font;
        };
      };
    };
  };

  programs.foot = {
    enable = true;

    settings = {
      main = {
        pad = "10x10";
      };

      scrollback = {
        lines = 2000;
        multiplier = 1.0;
      };

      cursor = {
        blink = "yes";
        blink-rate = 500;
      };

      bell = {
        system = "no";
      };

      csd = {
        preferred = "none";
      };
    };
  };
}
