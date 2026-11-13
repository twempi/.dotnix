{
  flake.modules.nixos.sway = {
    lib,
    pkgs,
    ...
  }: let
    systemdAwareSwayfxUnwrapped = pkgs.symlinkJoin {
      inherit (pkgs.swayfx-unwrapped) pname version passthru meta;
      paths = [pkgs.swayfx-unwrapped];

      postBuild = ''
        cp --remove-destination \
          ${pkgs.swayfx-unwrapped}/share/wayland-sessions/sway.desktop \
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
        package = pkgs.swayfx.override {
          swayfx-unwrapped = systemdAwareSwayfxUnwrapped;
        };
        wrapperFeatures.gtk = true;
        extraOptions = [
          "--unsupported-gpu"
        ];
        # The default list without swaylock; the Amane shell locks the session.
        extraPackages = with pkgs; [brightnessctl foot grim pulseaudio swayidle wmenu];
      };
    };

    xdg.portal.config.sway.default = lib.mkForce ["wlr" "gtk"];
  };
}
