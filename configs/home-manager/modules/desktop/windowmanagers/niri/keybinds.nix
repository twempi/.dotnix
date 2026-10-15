{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config.lib.niri) actions;
  noctalia = args: actions.spawn ([config.edward.noctalia.commands.niri "msg"] ++ args);
in {
  programs.niri.settings.binds =
    {
      "Mod+Q".action = actions.close-window;
      "Mod+V".action = actions.toggle-window-floating;
      "Mod+F".action = actions.fullscreen-window;
      "Mod+Return".action.spawn = ["${pkgs.foot}/bin/foot"];
      "Mod+B".action.spawn = ["helium"];
      "Mod+E".action.spawn = ["${pkgs.foot}/bin/foot" "-e" "${pkgs.yazi}/bin/yazi"];
      "Mod+Shift+E".action.spawn = ["${pkgs.nautilus}/bin/nautilus"];
      "Mod+M".action.spawn = ["spotify"];
      "Mod+O".action.spawn = ["${pkgs.obsidian}/bin/obsidian"];
      "Mod+N".action.spawn = ["${pkgs.foot}/bin/foot" "-e" "nvim"];
      "Mod+Shift+B".action.spawn = ["${pkgs.foot}/bin/foot" "-e" "${pkgs.bluetui}/bin/bluetui"];

      "Mod+Space".action = noctalia ["panel-toggle" "launcher"];
      "Mod+U".action = noctalia ["panel-toggle" "launcher" "/emo"];
      "Mod+Y".action = noctalia ["panel-toggle" "clipboard"];
      "Mod+Shift+N".action = noctalia ["panel-toggle" "control-center"];
      "Mod+Escape".action = noctalia ["panel-toggle" "session"];
      "Mod+Shift+W".action = noctalia ["panel-toggle" "wallpaper"];
      "Mod+Shift+R".action = noctalia ["config-reload"];
      "Mod+Comma".action = noctalia ["settings-toggle"];
      "Mod+Shift+S".action = noctalia ["screenshot-region"];
      "Print".action = noctalia ["screenshot-fullscreen"];

      "Mod+H".action = actions.focus-column-left;
      "Mod+J".action = actions.focus-window-down;
      "Mod+K".action = actions.focus-window-up;
      "Mod+L".action = actions.focus-column-right;
      "Mod+Ctrl+H".action = actions.move-column-left;
      "Mod+Ctrl+J".action = actions.move-window-down;
      "Mod+Ctrl+K".action = actions.move-window-up;
      "Mod+Ctrl+L".action = actions.move-column-right;
      "Mod+Shift+H".action = actions.set-column-width "+50";
      "Mod+Shift+L".action = actions.set-column-width "-50";
      "Mod+Shift+J".action = actions.set-window-height "+50";
      "Mod+Shift+K".action = actions.set-window-height "-50";
      "Mod+BracketLeft".action = actions.consume-or-expel-window-left;
      "Mod+BracketRight".action = actions.consume-or-expel-window-right;
      "Mod+C".action = actions.center-column;
      "Mod+Tab".action = actions.toggle-overview;

      "XF86AudioLowerVolume" = {
        allow-when-locked = true;
        action = noctalia ["volume-down"];
      };
      "XF86AudioRaiseVolume" = {
        allow-when-locked = true;
        action = noctalia ["volume-up"];
      };
      "XF86AudioMute" = {
        allow-when-locked = true;
        action = noctalia ["volume-mute"];
      };
      "XF86AudioMicMute" = {
        allow-when-locked = true;
        action = noctalia ["mic-mute"];
      };
      "XF86MonBrightnessUp".action = noctalia ["brightness-up"];
      "XF86MonBrightnessDown".action = noctalia ["brightness-down"];
      "XF86AudioNext".action = noctalia ["media" "next"];
      "XF86AudioPrev".action = noctalia ["media" "previous"];
      "XF86AudioPlay".action = noctalia ["media" "toggle"];
      "XF86AudioPause".action = noctalia ["media" "toggle"];
    }
    // builtins.listToAttrs (lib.concatMap (i: let
      key =
        if i == 10
        then "0"
        else toString i;
      workspace = toString i;
    in [
      {
        name = "Mod+${key}";
        value.action = actions.focus-workspace workspace;
      }
      {
        name = "Mod+Shift+${key}";
        value.action.move-window-to-workspace = workspace;
      }
    ]) (lib.range 1 10));
}
