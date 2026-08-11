{
  lib,
  pkgs,
  ...
}: let
  systemdAwareSwayUnwrapped = pkgs.symlinkJoin {
    inherit (pkgs.sway-unwrapped) pname version passthru meta;
    paths = [pkgs.sway-unwrapped];

    postBuild = ''
      cp --remove-destination \
        ${pkgs.sway-unwrapped}/share/wayland-sessions/sway.desktop \
        $out/share/wayland-sessions/sway.desktop
      substituteInPlace $out/share/wayland-sessions/sway.desktop \
        --replace-fail \
        "DesktopNames=sway;wlroots" \
        "DesktopNames=sway;wlroots;X-NIXOS-SYSTEMD-AWARE"
    '';
  };
in {
  programs = {
    sway = {
      enable = true;
      package = pkgs.sway.override {
        sway-unwrapped = systemdAwareSwayUnwrapped;
      };
      wrapperFeatures.gtk = true;
      extraOptions = [
        "--unsupported-gpu"
      ];
    };
  };

  xdg.portal.config.sway.default = lib.mkForce ["wlr" "gtk"];
}
