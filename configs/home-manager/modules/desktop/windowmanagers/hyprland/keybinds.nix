{
  config,
  lib,
  pkgs,
  ...
}: let
  lua = lib.generators.mkLuaInline;
  toLua = lib.generators.toLua {};
  uwsmApp = "uwsm app --";

  modKey = key: lua ''mod .. " + ${key}"'';
  execCmd = command: lua "hl.dsp.exec_cmd(${toLua command})";
  execLocal = name: lua "hl.dsp.exec_cmd(${name})";
  bind = key: action: {
    _args = [
      key
      action
    ];
  };
  bindWith = key: action: opts: {
    _args = [
      key
      action
      opts
    ];
  };
  resize = x: y:
    lua "hl.dsp.window.resize({ x = ${toString x}, y = ${toString y}, relative = true })";
  workspaceKey = ws:
    if ws == 10
    then "0"
    else toString ws;
  workspaceBind = ws: let
    key = workspaceKey ws;
    workspace = toString ws;
  in [
    (bind (modKey key) (lua "hl.dsp.focus({ workspace = ${workspace} })"))
    (bind (modKey "SHIFT + ${key}") (lua "hl.dsp.window.move({ workspace = ${workspace} })"))
  ];
  keycodeWorkspaceBinds = builtins.concatLists (builtins.genList (
      i: let
        ws = i + 1;
        code = i + 10;
        workspace = toString ws;
      in [
        (bind (modKey "code:${toString code}") (lua "hl.dsp.focus({ workspace = ${workspace} })"))
        (bind (modKey "SHIFT + code:${toString code}") (lua "hl.dsp.window.move({ workspace = ${workspace}, follow = false })"))
      ]
    )
    9);
  forceKillActive = "hyprctl activewindow -j | ${pkgs.jq}/bin/jq -r '.pid // empty' | ${pkgs.findutils}/bin/xargs -r kill";
  quickShellToggle = name:
    bind (modKey "ALT + ${name.key}") (lua ''hl.dsp.exec_cmd(qs .. " toggle ${name.panel}")'');
in {
  wayland.windowManager.hyprland.settings = {
    # Apps
    colorPicker = {
      _var = "${uwsmApp} ${pkgs.hyprpicker}/bin/hyprpicker -a";
    };
    notiCenter = {
      _var = "${pkgs.swaynotificationcenter}/bin/swaync-client -t -sw";
    };

    # terminal = { _var = "${pkgs.ghostty}/bin/ghostty"; };
    terminal = {
      _var = "${uwsmApp} ${pkgs.kitty}/bin/kitty";
    };
    # browser = { _var = "${pkgs.brave}/bin/brave"; };
    # browser = { _var = "zen-beta"; };
    browser = {
      _var = "${uwsmApp} helium";
    };
    explorer1 = {
      _var = "${uwsmApp} ${pkgs.kitty}/bin/kitty -e ${pkgs.yazi}/bin/yazi";
    };
    explorer2 = {
      _var = "${uwsmApp} ${pkgs.nautilus}/bin/nautilus";
    };
    notes = {
      _var = "${uwsmApp} ${pkgs.obsidian}/bin/obsidian";
    };
    bluetooth = {
      _var = "${uwsmApp} ${pkgs.kitty}/bin/kitty -e ${pkgs.bluetui}/bin/bluetui";
    };
    editor = {
      _var = "${uwsmApp} ${pkgs.kitty}/bin/kitty -e nvim";
    };

    mod = {
      _var = "SUPER";
    };
    qs = {
      _var = "${config.home.profileDirectory}/bin/qs-manager";
    };

    bind =
      [
        # Basic
        (bind (modKey "Q") (lua "hl.dsp.window.close()"))
        (bind (modKey "SHIFT + Q") (execCmd forceKillActive))
        (bind (modKey "V") (lua ''hl.dsp.window.float({ action = "toggle" })''))
        (bind (modKey "F") (lua ''hl.dsp.window.fullscreen({ mode = "maximized" })''))
        (bind (modKey "SHIFT + F") (lua ''hl.dsp.window.fullscreen({ mode = "fullscreen" })''))

        (bind (modKey "return") (execLocal "terminal"))
        (bind (modKey "B") (execLocal "browser"))
        (bind (modKey "E") (execLocal "explorer1"))
        (bind (modKey "SHIFT + E") (execLocal "explorer2"))
        (bind (modKey "M") (execCmd "${uwsmApp} spotify"))
        (bind (modKey "O") (execLocal "notes"))
        (bind (modKey "N") (execLocal "editor"))
        (bind (modKey "SHIFT + B") (execLocal "bluetooth"))
        (bind (modKey "SHIFT + N") (execLocal "notiCenter"))
        (bind (modKey "Escape") (execCmd "${uwsmApp} qs-power"))

        (bind (modKey "Z") (execLocal "colorPicker"))
        (bind (modKey "SHIFT + W") (execCmd "${uwsmApp} qs-wallpaper"))
        (bind (modKey "SHIFT + R") (execCmd "${./reload.sh}"))

        # Screenshots
        (bind (modKey "SHIFT + S") (execCmd "way-screenshot area"))
        (bind "Print" (execCmd "way-screenshot screen"))

        # Launcher / emoji / clipboard
        (bind (modKey "Space") (execCmd "${uwsmApp} qs-launcher"))
        (bind (modKey "U") (execCmd "${uwsmApp} qs-emoji"))
        (bind (modKey "Y") (execCmd "${uwsmApp} qs-clipboard"))

        # Move focus with mod + HJKL(Vim keys)
        (bind (modKey "H") (lua ''hl.dsp.focus({ direction = "left" })''))
        (bind (modKey "L") (lua ''hl.dsp.focus({ direction = "right" })''))
        (bind (modKey "J") (lua ''hl.dsp.focus({ direction = "down" })''))
        (bind (modKey "K") (lua ''hl.dsp.focus({ direction = "up" })''))

        # Move windows with mod + CTRL + HJKL(Vim keys)
        (bind (modKey "CTRL + H") (lua ''hl.dsp.window.move({ direction = "left" })''))
        (bind (modKey "CTRL + L") (lua ''hl.dsp.window.move({ direction = "right" })''))
        (bind (modKey "CTRL + J") (lua ''hl.dsp.window.move({ direction = "down" })''))
        (bind (modKey "CTRL + K") (lua ''hl.dsp.window.move({ direction = "up" })''))

        # Cycle through active workspaces
        (bind (modKey "TAB") (lua ''hl.dsp.focus({ workspace = "e+1" })''))
        (bind (modKey "SHIFT + TAB") (lua ''hl.dsp.focus({ workspace = "e-1" })''))

        # QuickShell toggles (merged from ilyamiro, remapped to avoid conflicts)
        (quickShellToggle {
          key = "M";
          panel = "monitors";
        })
        (quickShellToggle {
          key = "S";
          panel = "stewart";
        })
        (quickShellToggle {
          key = "Q";
          panel = "music";
        })
        (quickShellToggle {
          key = "B";
          panel = "battery";
        })
        (quickShellToggle {
          key = "W";
          panel = "wallpaper";
        })
        (quickShellToggle {
          key = "C";
          panel = "calendar";
        })
        (quickShellToggle {
          key = "N";
          panel = "network";
        })
        (quickShellToggle {
          key = "T";
          panel = "focustime";
        })
        (quickShellToggle {
          key = "V";
          panel = "volume";
        })
        (quickShellToggle {
          key = "G";
          panel = "guide";
        })

        # Move windows with mouse
        (bindWith (modKey "mouse:272") (lua "hl.dsp.window.drag()") {mouse = true;})
        # Resize windows with mouse
        (bindWith (modKey "mouse:273") (lua "hl.dsp.window.resize()") {mouse = true;})

        # Resize windows with mod + Shift + HJKL(vim keys)
        (bindWith (modKey "SHIFT + H") (resize (-50) 0) {repeating = true;})
        (bindWith (modKey "SHIFT + L") (resize 50 0) {repeating = true;})
        (bindWith (modKey "SHIFT + J") (resize 0 (-50)) {repeating = true;})
        (bindWith (modKey "SHIFT + K") (resize 0 50) {repeating = true;})

        # Laptop multimedia keys for volume and LCD brightness
        (bindWith "XF86AudioLowerVolume" (execCmd "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-") {
          locked = true;
          repeating = true;
        })
        (bindWith "XF86AudioRaiseVolume" (execCmd "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+") {
          locked = true;
          repeating = true;
        })
        (bindWith "XF86AudioMute" (execCmd "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle") {
          locked = true;
          repeating = true;
        })
        (bindWith "XF86AudioMicMute" (execCmd "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle") {
          locked = true;
          repeating = true;
        })
        (bindWith "XF86MonBrightnessUp" (execCmd "brightnessctl set 5%+") {
          locked = true;
          repeating = true;
        })
        (bindWith "XF86MonBrightnessDown" (execCmd "brightnessctl set 5%-") {
          locked = true;
          repeating = true;
        })

        # Requires playerctl
        (bindWith "XF86AudioNext" (execCmd "playerctl next") {locked = true;})
        (bindWith "XF86AudioPause" (execCmd "playerctl play-pause") {locked = true;})
        (bindWith "XF86AudioPlay" (execCmd "playerctl play-pause") {locked = true;})
        (bindWith "XF86AudioPrev" (execCmd "playerctl previous") {locked = true;})
      ]
      ++ builtins.concatLists (map workspaceBind [1 2 3 4 5 6 7 9 10])
      ++ keycodeWorkspaceBinds;
  };
}
