{
  pkgs,
  inputs,
  ...
}: let
  system = pkgs.stdenv.hostPlatform.system;

  hyprPackage = inputs.hyprland.packages.${system}.hyprland.overrideAttrs (old: {
    postInstall =
      (old.postInstall or "")
      + ''
        desktop="$out/share/wayland-sessions/hyprland.desktop"

        if [ -f "$desktop" ]; then
          grep -q '^NoDisplay=' "$desktop" || echo 'NoDisplay=true' >> "$desktop"
          grep -q '^Hidden=' "$desktop" || echo 'Hidden=true' >> "$desktop"
        fi
      '';
  });

  hyprPortal =
    inputs.hyprland.packages.${system}.xdg-desktop-portal-hyprland;
in {
  programs = {
    hyprland = {
      enable = true;
      withUWSM = true;
      xwayland.enable = true;

      package = hyprPackage;
      portalPackage = hyprPortal;
    };
  };

  xdg.portal.config.hyprland.default = ["hyprland" "gtk"];
}
