{
  flake.modules.homeManager.hyprland = {
    pkgs,
    config,
    lib,
    ...
  }: let
    lua = lib.generators.mkLuaInline;
    toLua = lib.generators.toLua {};
    exec = command: "  hl.exec_cmd(${toLua command})";
    execWithRules = command: rules: "  hl.exec_cmd(${toLua command}, ${toLua rules})";
    # The Amane shell starts with the session's systemd target; awww draws the wallpaper Noctalia used to.
    autostart = [
      (exec "uwsm app -- ${pkgs.awww}/bin/awww-daemon")
      (execWithRules "uwsm app -- spotify" {workspace = "9 silent";})
      (execWithRules "uwsm app -- ${pkgs.obsidian}/bin/obsidian" {workspace = "10 silent";})
      (exec "sleep 4 && ${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 1")
      (exec "sleep 5 && ${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 1")
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
    };
  };
}
