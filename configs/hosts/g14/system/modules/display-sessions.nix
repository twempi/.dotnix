{
  config,
  lib,
  pkgs,
  ...
}: let
  g14DrmDevices = pkgs.writeShellApplication {
    name = "g14-drm-devices";

    text = ''
      cards=()
      ordered=()

      add_card() {
        local candidate="$1"
        local existing

        for existing in "''${ordered[@]}"; do
          if [[ "$existing" == "$candidate" ]]; then
            return
          fi
        done

        ordered+=("$candidate")
      }

      has_connector_prefix() {
        local card="$1"
        local prefix="$2"
        local connector_path
        local connector_name

        for connector_path in /sys/class/drm/"$card"-*; do
          [[ -e "$connector_path" ]] || continue
          [[ -d "$connector_path" ]] || continue

          connector_name="''${connector_path##*/}"
          connector_name="''${connector_name#"$card"-}"

          if [[ "$connector_name" == "$prefix"* ]]; then
            return 0
          fi
        done

        return 1
      }

      for sys_card in /sys/class/drm/card[0-9]; do
        [[ -e "$sys_card" ]] || continue

        card="''${sys_card##*/}"
        [[ -e "/dev/dri/$card" ]] || continue

        cards+=("$card")
      done

      for card in "''${cards[@]}"; do
        if has_connector_prefix "$card" "eDP-"; then
          add_card "$card"
        fi
      done

      for card in "''${cards[@]}"; do
        if has_connector_prefix "$card" "HDMI-A-"; then
          add_card "$card"
        fi
      done

      for card in "''${cards[@]}"; do
        add_card "$card"
      done

      output=""
      for card in "''${ordered[@]}"; do
        if [[ -n "$output" ]]; then
          output+=":"
        fi

        output+="/dev/dri/$card"
      done

      printf '%s\n' "$output"
    '';
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

  g14StartMango = pkgs.writeShellApplication {
    name = "g14-start-mango";

    text = ''
      ${exportDrmDevices}
      export WLR_DRM_NO_ATOMIC=1

      exec ${config.programs.mango.package}/bin/mango "$@"
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
      (pkgs.writeTextDir "share/wayland-sessions/mango.desktop" ''
        [Desktop Entry]
        Encoding=UTF-8
        Name=Mango
        DesktopNames=mango;wlroots
        Comment=mango WM
        Exec=${lib.getExe g14StartMango}
        Icon=mango
        Type=Application
      '')
    ];

    passthru.providedSessions = [
      "hyprland"
      "hyprland-uwsm"
      "sway"
      "mango"
    ];
  };
in {
  environment.systemPackages = [
    g14DrmDevices
  ];

  services.displayManager.sessionPackages = lib.mkForce [
    g14WaylandSessions
  ];
}
