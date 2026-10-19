{
  flake.modules.homeManager.niri = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (config.lib.niri) actions;
    workspaces = lib.range 1 9;
    workspaceBinds = builtins.listToAttrs (lib.concatMap (i: [
        {
          name = "Mod+${toString i}";
          value.action.focus-workspace = i;
        }
        {
          name = "Mod+Ctrl+${toString i}";
          value.action.move-column-to-workspace = i;
        }
      ])
      workspaces);
  in {
    # Mirrors niri's default config (resources/default-config.kdl), with the
    # terminal, launcher and lock screen swapped for what is installed.
    programs.niri.settings.binds =
      {
        "Mod+Shift+Slash".action = actions.show-hotkey-overlay;

        "Mod+T" = {
          hotkey-overlay.title = "Open a Terminal: foot";
          action.spawn = ["${pkgs.foot}/bin/foot"];
        };
        "Mod+D" = {
          hotkey-overlay.title = "Run an Application: amane launcher";
          action.spawn = ["amane" "ipc" "call" "launcher" "toggle"];
        };
        "Super+Alt+L" = {
          hotkey-overlay.title = "Lock the Screen: amane";
          action.spawn = ["amane" "ipc" "call" "lock"];
        };
        "Mod+Shift+T" = {
          hotkey-overlay.title = "Switch Theme";
          action.spawn = ["theme-switch" "--pick"];
        };

        "XF86AudioRaiseVolume" = {
          allow-when-locked = true;
          action.spawn-sh = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+ -l 1.0";
        };
        "XF86AudioLowerVolume" = {
          allow-when-locked = true;
          action.spawn-sh = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1-";
        };
        "XF86AudioMute" = {
          allow-when-locked = true;
          action.spawn-sh = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
        };
        "XF86AudioMicMute" = {
          allow-when-locked = true;
          action.spawn-sh = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
        };

        "XF86AudioPlay" = {
          allow-when-locked = true;
          action.spawn-sh = "playerctl play-pause";
        };
        "XF86AudioStop" = {
          allow-when-locked = true;
          action.spawn-sh = "playerctl stop";
        };
        "XF86AudioPrev" = {
          allow-when-locked = true;
          action.spawn-sh = "playerctl previous";
        };
        "XF86AudioNext" = {
          allow-when-locked = true;
          action.spawn-sh = "playerctl next";
        };

        "XF86MonBrightnessUp" = {
          allow-when-locked = true;
          action.spawn = ["brightnessctl" "--class=backlight" "set" "+10%"];
        };
        "XF86MonBrightnessDown" = {
          allow-when-locked = true;
          action.spawn = ["brightnessctl" "--class=backlight" "set" "10%-"];
        };

        "Mod+O" = {
          repeat = false;
          action = actions.toggle-overview;
        };
        "Mod+Q" = {
          repeat = false;
          action = actions.close-window;
        };

        "Mod+Left".action = actions.focus-column-left;
        "Mod+Down".action = actions.focus-window-down;
        "Mod+Up".action = actions.focus-window-up;
        "Mod+Right".action = actions.focus-column-right;
        "Mod+H".action = actions.focus-column-left;
        "Mod+J".action = actions.focus-window-down;
        "Mod+K".action = actions.focus-window-up;
        "Mod+L".action = actions.focus-column-right;

        "Mod+Ctrl+Left".action = actions.move-column-left;
        "Mod+Ctrl+Down".action = actions.move-window-down;
        "Mod+Ctrl+Up".action = actions.move-window-up;
        "Mod+Ctrl+Right".action = actions.move-column-right;
        "Mod+Ctrl+H".action = actions.move-column-left;
        "Mod+Ctrl+J".action = actions.move-window-down;
        "Mod+Ctrl+K".action = actions.move-window-up;
        "Mod+Ctrl+L".action = actions.move-column-right;

        "Mod+Home".action = actions.focus-column-first;
        "Mod+End".action = actions.focus-column-last;
        "Mod+Ctrl+Home".action = actions.move-column-to-first;
        "Mod+Ctrl+End".action = actions.move-column-to-last;

        "Mod+Shift+Left".action = actions.focus-monitor-left;
        "Mod+Shift+Down".action = actions.focus-monitor-down;
        "Mod+Shift+Up".action = actions.focus-monitor-up;
        "Mod+Shift+Right".action = actions.focus-monitor-right;
        "Mod+Shift+H".action = actions.focus-monitor-left;
        "Mod+Shift+J".action = actions.focus-monitor-down;
        "Mod+Shift+K".action = actions.focus-monitor-up;
        "Mod+Shift+L".action = actions.focus-monitor-right;

        "Mod+Shift+Ctrl+Left".action = actions.move-column-to-monitor-left;
        "Mod+Shift+Ctrl+Down".action = actions.move-column-to-monitor-down;
        "Mod+Shift+Ctrl+Up".action = actions.move-column-to-monitor-up;
        "Mod+Shift+Ctrl+Right".action = actions.move-column-to-monitor-right;
        "Mod+Shift+Ctrl+H".action = actions.move-column-to-monitor-left;
        "Mod+Shift+Ctrl+J".action = actions.move-column-to-monitor-down;
        "Mod+Shift+Ctrl+K".action = actions.move-column-to-monitor-up;
        "Mod+Shift+Ctrl+L".action = actions.move-column-to-monitor-right;

        "Mod+Page_Down".action = actions.focus-workspace-down;
        "Mod+Page_Up".action = actions.focus-workspace-up;
        "Mod+U".action = actions.focus-workspace-down;
        "Mod+I".action = actions.focus-workspace-up;
        "Mod+Ctrl+Page_Down".action = actions.move-column-to-workspace-down;
        "Mod+Ctrl+Page_Up".action = actions.move-column-to-workspace-up;
        "Mod+Ctrl+U".action = actions.move-column-to-workspace-down;
        "Mod+Ctrl+I".action = actions.move-column-to-workspace-up;

        "Mod+Shift+Page_Down".action = actions.move-workspace-down;
        "Mod+Shift+Page_Up".action = actions.move-workspace-up;
        "Mod+Shift+U".action = actions.move-workspace-down;
        "Mod+Shift+I".action = actions.move-workspace-up;

        "Mod+WheelScrollDown" = {
          cooldown-ms = 150;
          action = actions.focus-workspace-down;
        };
        "Mod+WheelScrollUp" = {
          cooldown-ms = 150;
          action = actions.focus-workspace-up;
        };
        "Mod+Ctrl+WheelScrollDown" = {
          cooldown-ms = 150;
          action = actions.move-column-to-workspace-down;
        };
        "Mod+Ctrl+WheelScrollUp" = {
          cooldown-ms = 150;
          action = actions.move-column-to-workspace-up;
        };

        "Mod+WheelScrollRight".action = actions.focus-column-right;
        "Mod+WheelScrollLeft".action = actions.focus-column-left;
        "Mod+Ctrl+WheelScrollRight".action = actions.move-column-right;
        "Mod+Ctrl+WheelScrollLeft".action = actions.move-column-left;

        "Mod+Shift+WheelScrollDown".action = actions.focus-column-right;
        "Mod+Shift+WheelScrollUp".action = actions.focus-column-left;
        "Mod+Ctrl+Shift+WheelScrollDown".action = actions.move-column-right;
        "Mod+Ctrl+Shift+WheelScrollUp".action = actions.move-column-left;

        "Mod+BracketLeft".action = actions.consume-or-expel-window-left;
        "Mod+BracketRight".action = actions.consume-or-expel-window-right;

        "Mod+Comma".action = actions.consume-window-into-column;
        "Mod+Period".action = actions.expel-window-from-column;

        "Mod+R".action = actions.switch-preset-column-width;
        "Mod+Shift+R".action = actions.switch-preset-column-width-back;
        "Mod+Ctrl+Shift+R".action = actions.switch-preset-window-height;
        "Mod+Ctrl+R".action = actions.reset-window-height;

        "Mod+F".action = actions.maximize-column;
        "Mod+Shift+F".action = actions.fullscreen-window;
        "Mod+M".action = actions.maximize-window-to-edges;
        "Mod+Ctrl+F".action = actions.expand-column-to-available-width;

        "Mod+C".action = actions.center-column;
        "Mod+Ctrl+C".action = actions.center-visible-columns;

        "Mod+Minus".action = actions.set-column-width "-10%";
        "Mod+Equal".action = actions.set-column-width "+10%";
        "Mod+Shift+Minus".action = actions.set-window-height "-10%";
        "Mod+Shift+Equal".action = actions.set-window-height "+10%";

        "Mod+V".action = actions.toggle-window-floating;
        "Mod+Shift+V".action = actions.switch-focus-between-floating-and-tiling;

        "Mod+W".action = actions.toggle-column-tabbed-display;

        "Print".action.screenshot = {};
        "Ctrl+Print".action.screenshot-screen = {};
        "Alt+Print".action.screenshot-window = {};

        "Mod+Escape" = {
          allow-inhibiting = false;
          action = actions.toggle-keyboard-shortcuts-inhibit;
        };

        "Mod+Shift+E".action = actions.quit;
        "Ctrl+Alt+Delete".action = actions.quit;

        "Mod+Shift+P".action = actions.power-off-monitors;
      }
      // workspaceBinds;
  };
}
