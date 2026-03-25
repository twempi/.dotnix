{lib, ...}: {
  stylix.targets.foot.enable = true;

  programs.foot = {
    enable = true;

    settings = {
      main = {
        font = lib.mkForce "Fira Code:size=12";
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
      colors-dark = {
        alpha = lib.mkForce "1.0";
      };
      csd = {
        preferred = "none";
      };
    };
  };
}
