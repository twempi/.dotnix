{pkgs, ...}: {
  wayland.windowManager.sway = {
    config = {
      bars = [];

      defaultWorkspace = "workspace 1";

      startup = [
        {command = "awww-daemon";}
        {command = "${pkgs.openrgb}/bin/openrgb --profile ~/.config/OpenRGB/black.orp";}
        {command = "${pkgs.waybar}/bin/waybar -c ~/.config/waybar/sway.jsonc -s ~/.config/waybar/sway.css";}

        # Set volume to 100%
        {command = "sleep 4 && ${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 1";}
        {command = "sleep 5 && ${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 1";}

        # Clipboard history
        {command = "${pkgs.cliphist}/bin/cliphist wipe";}
        {command = "${pkgs.wl-clipboard}/bin/wl-paste --type text --watch ${pkgs.cliphist}/bin/cliphist store";}

        {
          command = "${pkgs.dbus}/bin/dbus-update-activation-environment --systemd WAYLAND_DISPLAY SWAYSOCK XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_DATA_DIRS PATH DBUS_SESSION_BUS_ADDRESS";
          always = true;
        }
        {
          command = "${pkgs.systemd}/bin/systemctl --user import-environment WAYLAND_DISPLAY SWAYSOCK XDG_CURRENT_DESKTOP XDG_SESSION_TYPE XDG_DATA_DIRS PATH DBUS_SESSION_BUS_ADDRESS";
          always = true;
        }

        # {command = "obsidian";}
        # {command = "spotify";}
      ];

      window = {
        border = 2;
        titlebar = false;
      };

      input = {
        "*" = {
          xkb_layout = "us";
          accel_profile = "flat";
          pointer_accel = "0.0";
          xkb_numlock = "enabled";
        };

        "type:touchpad" = {
          natural_scroll = "disabled";
          dwt = "disabled";
        };
      };

      focus = {
        followMouse = "yes";
      };
    };

    # extraConfig = ''
    #   default_dim_inactive 0.2
    # '';
  };
}
