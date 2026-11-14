{config, ...}: let
  inherit (config.flake.modules) homeManager;
in {
  flake.modules.homeManager.sway = {
    config,
    pkgs,
    ...
  }: {
    # The Amane shell replaces Waybar, Rofi and SwayNC.
    imports = with homeManager; [
      amane
    ];

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

    home.sessionVariables = {
      NIXOS_OZONE_WL = 1;
      MOZ_ENABLE_WAYLAND = 1;
      # XDG_CURRENT_DESKTOP = "sway";
      # XDG_SESSION_DESKTOP = "sway";
      XDG_SESSION_TYPE = "wayland";
      GDK_BACKEND = "wayland,x11";
      QT_QPA_PLATFORM = "wayland;xcb";
    };
  };
}
