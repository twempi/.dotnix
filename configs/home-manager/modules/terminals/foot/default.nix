{
  flake.modules.homeManager.foot = {
    stylix.targets.foot = {
      enable = true;
      colors.enable = true;
    };

    programs.foot = {
      enable = true;

      settings = {
        main = {
          pad = "10x10";
          selection-target = "none";
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

        security = {
          osc52 = "copy-enabled";
        };
      };
    };
  };
}
