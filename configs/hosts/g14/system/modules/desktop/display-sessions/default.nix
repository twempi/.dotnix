{
  flake.modules.nixos.g14-display-sessions = {
    config,
    lib,
    pkgs,
    ...
  }: let
    g14DrmDevices = pkgs.writeShellApplication {
      name = "g14-drm-devices";

      text = builtins.readFile ./drm-devices.sh;
    };

    exportDrmDevices = ''
      drm_devices="$(${lib.getExe g14DrmDevices})"
      if [[ -n "$drm_devices" ]]; then
        export AQ_DRM_DEVICES="$drm_devices"
        export WLR_DRM_DEVICES="$drm_devices"
      fi
    '';

    g14StartHyprland = pkgs.writeShellApplication {
      name = "g14-start-hyprland";

      text = ''
        ${exportDrmDevices}

        exec ${config.programs.hyprland.package}/bin/start-hyprland "$@"
      '';
    };

    g14StartSway = pkgs.writeShellApplication {
      name = "g14-start-sway";

      text = ''
        ${exportDrmDevices}

        exec ${config.programs.sway.package}/bin/sway "$@"
      '';
    };

    g14WaylandSessions = pkgs.symlinkJoin {
      name = "g14-wayland-sessions";

      paths = [
        (pkgs.writeTextDir "share/wayland-sessions/hyprland.desktop" ''
          [Desktop Entry]
          Name=Hyprland
          Comment=An intelligent dynamic tiling Wayland compositor
          Exec=${lib.getExe g14StartHyprland}
          Type=Application
          DesktopNames=Hyprland
          Keywords=tiling;wayland;compositor;
        '')
        (pkgs.writeTextDir "share/wayland-sessions/hyprland-uwsm.desktop" ''
          [Desktop Entry]
          Name=Hyprland (uwsm-managed)
          Comment=An intelligent dynamic tiling Wayland compositor
          Exec=${lib.getExe config.programs.uwsm.package} start -e -D Hyprland hyprland.desktop
          TryExec=${lib.getExe config.programs.uwsm.package}
          DesktopNames=Hyprland
          Type=Application
        '')
        (pkgs.writeTextDir "share/wayland-sessions/sway.desktop" ''
          [Desktop Entry]
          Name=Sway
          Comment=An i3-compatible Wayland compositor
          Exec=${lib.getExe g14StartSway}
          Type=Application
          DesktopNames=sway;wlroots;X-NIXOS-SYSTEMD-AWARE
        '')
      ];

      passthru.providedSessions = [
        "hyprland"
        "hyprland-uwsm"
        "sway"
      ];
    };
  in {
    environment.systemPackages = [
      g14DrmDevices
    ];

    services.displayManager.sessionPackages = lib.mkForce [
      g14WaylandSessions
    ];
  };
}
