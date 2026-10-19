{inputs, ...}: {
  flake.modules.homeManager.niri = {
    config,
    lib,
    pkgs,
    ...
  }: {
    programs.niri.settings = {
      spawn-at-startup = [
        {command = ["amane" "run"];}
      ];

      input = {
        keyboard = {
          xkb.layout = "us";
          numlock = true;
        };
        mouse = {
          accel-profile = "flat";
          accel-speed = 0.0;
        };
        touchpad = {
          tap = true;
          natural-scroll = false;
          dwt = false;
        };
        focus-follows-mouse.enable = true;
      };

      layout = {
        gaps = 4;
        border.width = 2;
        focus-ring.enable = false;
        default-column-width.proportion = 0.5;
        preset-column-widths = [
          {proportion = 1.0 / 3.0;}
          {proportion = 0.5;}
          {proportion = 2.0 / 3.0;}
        ];
        center-focused-column = "on-overflow";
      };

      # # Sort keys keep workspace 10 after workspace 9.
      # workspaces = builtins.listToAttrs (map (i: {
      #   name = lib.fixedWidthNumber 2 i;
      #   value.name = toString i;
      # }) (lib.range 1 10));

      prefer-no-csd = true;
      screenshot-path = "${config.home.homeDirectory}/Pictures/Screenshots/Screenshot-%Y-%m-%d_%H:%M:%S.png";
      xwayland-satellite.path = lib.getExe inputs.niri.packages.${pkgs.stdenv.hostPlatform.system}.xwayland-satellite-unstable;
    };
  };
}
