{
  lib,
  pkgs,
  ...
}: {
  programs = {
    sway = {
      enable = true;
      # package = pkgs.swayfx;
      wrapperFeatures.gtk = true;
      extraOptions = [
        "--unsupported-gpu"
      ];
    };
  };

  xdg.portal.config.sway.default = lib.mkForce ["wlr" "gtk"];
}
