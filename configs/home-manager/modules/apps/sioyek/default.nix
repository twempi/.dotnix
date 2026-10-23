{
  flake.modules.homeManager.sioyek = {lib, ...}: {
    stylix.targets.sioyek = {
      enable = true;
      colors.enable = true;
    };

    programs.sioyek = {
      enable = true;

      config.visual_mark_color = lib.mkForce "0.239216 0.282353 0.301961 0.15";
    };
  };
}
