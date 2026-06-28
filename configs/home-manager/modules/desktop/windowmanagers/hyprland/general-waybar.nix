{
  pkgs,
  config,
  lib,
  ...
}: let
  lua = lib.generators.mkLuaInline;
  toLua = lib.generators.toLua {};
  exec = command: "  hl.exec_cmd(${toLua command})";
  execWithRules = command: rules: "  hl.exec_cmd(${toLua command}, ${toLua rules})";
  autostart = [
    (exec "uwsm app -- ${pkgs.awww}/bin/awww-daemon")
    (exec "uwsm app -- ${pkgs.openrgb}/bin/openrgb --profile ~/.config/OpenRGB/black.orp")
    (exec "uwsm app -- ${pkgs.waybar}/bin/waybar -c ~/.config/waybar/hyprland.jsonc -s ~/.config/waybar/hyprland.css")
    (execWithRules "uwsm app -- spotify" {workspace = "9 silent";})
    (execWithRules "uwsm app -- ${pkgs.obsidian}/bin/obsidian" {workspace = "10 silent";})
    (exec "sleep 4 && ${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 1")
    (exec "sleep 5 && ${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 1")
    (exec "${pkgs.cliphist}/bin/cliphist wipe")
    (exec "uwsm app -- ${pkgs.wl-clipboard}/bin/wl-paste --type text --watch ${pkgs.cliphist}/bin/cliphist store")
  ];
in {
  wayland.windowManager.hyprland.settings = {
    on = {
      _args = [
        "hyprland.start"
        (lua ''
          function()
          ${lib.concatStringsSep "\n" autostart}
          end
        '')
      ];
    };

    config = {
      general = {
        "gaps_in" = 3;
        "gaps_out" = 5;
        "gaps_workspaces" = 50;

        "border_size" = 2;

        "col.active_border" = lib.mkForce "rgb(${config.lib.stylix.colors.base0A})";
        "col.inactive_border" = lib.mkForce "rgb(${config.lib.stylix.colors.base01})";

        "layout" = "dwindle";
      };

      decoration = {
        "rounding" = 0;
        "active_opacity" = 1;
        "inactive_opacity" = 0.9;
        "fullscreen_opacity" = 1;

        blur = {
          "enabled" = true;
          "size" = 6;
          "passes" = 2;
          "new_optimizations" = true;
          "ignore_opacity" = true;
          "xray" = false;
          "popups" = true;
          "special" = true;
        };

        shadow = {
          "enabled" = true;
          "range" = 5;
          "render_power" = 2;
          "color" = lib.mkDefault "rgba(1a1a1aee)"; # Fallback
        };
      };

      animations = {
        "enabled" = true;
      };

      dwindle = {
        "preserve_split" = true;
      };

      misc = {
        "force_default_wallpaper" = 0;
        "disable_hyprland_logo" = true;
        "disable_splash_rendering" = true;
        "initial_workspace_tracking" = 1;
      };

      ecosystem = {
        "no_update_news" = true;
        "no_donation_nag" = true;
      };

      input = {
        "kb_layout" = "us";
        "follow_mouse" = 1;
        "sensitivity" = 0;
        "numlock_by_default" = true;
        "accel_profile" = "flat";
        "force_no_accel" = true;

        touchpad = {
          "natural_scroll" = false;
          "scroll_factor" = 1;
        };
      };
    };

    curve = [
      {
        _args = [
          "easeOutQuint"
          {
            type = "bezier";
            points = [
              [0.23 1]
              [0.32 1]
            ];
          }
        ];
      }
      {
        _args = [
          "easeInOutCubic"
          {
            type = "bezier";
            points = [
              [0.65 0.05]
              [0.36 1]
            ];
          }
        ];
      }
      {
        _args = [
          "linear"
          {
            type = "bezier";
            points = [
              [0 0]
              [1 1]
            ];
          }
        ];
      }
      {
        _args = [
          "almostLinear"
          {
            type = "bezier";
            points = [
              [0.5 0.5]
              [0.75 1.0]
            ];
          }
        ];
      }
      {
        _args = [
          "quick"
          {
            type = "bezier";
            points = [
              [0.15 0]
              [0.1 1]
            ];
          }
        ];
      }
    ];

    animation = [
      {
        leaf = "global";
        enabled = true;
        speed = 10;
        bezier = "default";
      }
      {
        leaf = "border";
        enabled = true;
        speed = 5.39;
        bezier = "easeOutQuint";
      }
      {
        leaf = "windows";
        enabled = true;
        speed = 4.79;
        bezier = "easeOutQuint";
      }
      {
        leaf = "windowsIn";
        enabled = true;
        speed = 4.1;
        bezier = "easeOutQuint";
        style = "popin 87%";
      }
      {
        leaf = "windowsOut";
        enabled = true;
        speed = 1.49;
        bezier = "linear";
        style = "popin 87%";
      }
      {
        leaf = "fadeIn";
        enabled = true;
        speed = 1.73;
        bezier = "almostLinear";
      }
      {
        leaf = "fadeOut";
        enabled = true;
        speed = 1.46;
        bezier = "almostLinear";
      }
      {
        leaf = "fade";
        enabled = true;
        speed = 3.03;
        bezier = "quick";
      }
      {
        leaf = "layers";
        enabled = true;
        speed = 3.81;
        bezier = "easeOutQuint";
      }
      {
        leaf = "layersIn";
        enabled = true;
        speed = 4;
        bezier = "easeOutQuint";
        style = "fade";
      }
      {
        leaf = "layersOut";
        enabled = true;
        speed = 1.5;
        bezier = "linear";
        style = "fade";
      }
      {
        leaf = "fadeLayersIn";
        enabled = true;
        speed = 1.79;
        bezier = "almostLinear";
      }
      {
        leaf = "fadeLayersOut";
        enabled = true;
        speed = 1.39;
        bezier = "almostLinear";
      }
      {
        leaf = "workspaces";
        enabled = true;
        speed = 1.94;
        bezier = "almostLinear";
        style = "fade";
      }
      {
        leaf = "workspacesIn";
        enabled = true;
        speed = 1.21;
        bezier = "almostLinear";
        style = "fade";
      }
      {
        leaf = "workspacesOut";
        enabled = true;
        speed = 1.94;
        bezier = "almostLinear";
        style = "fade";
      }
    ];
  };
}
