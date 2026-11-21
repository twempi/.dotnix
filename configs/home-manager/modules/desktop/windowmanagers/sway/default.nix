{
  flake.modules.homeManager.sway = {
    config,
    pkgs,
    ...
  }: {
    stylix.targets.sway.enable = true;
    xdg.userDirs.extraConfig.SCREENSHOTS = "${config.home.homeDirectory}/Pictures/Screenshots";

    services.cliphist = {
      enable = true;
      systemdTargets = ["sway-session.target"];
    };

    # sway
    wayland.windowManager.sway = {
      systemd.enable = true;
      enable = true;
      # The NixOS sway module provides the package and its flags, as Hyprland does.
      package = null;
      xwayland = true;
      # swayfx --validate needs a DRM device, which the Nix build sandbox lacks.
      checkConfig = false;
    };
  };
}
