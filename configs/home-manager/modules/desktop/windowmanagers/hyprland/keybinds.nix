{
  lib,
  pkgs,
  ...
}: let
  lua = lib.generators.mkLuaInline;
  toLua = lib.generators.toLua {};
  uwsmApp = "uwsm app --";
  noctalia = "noctalia msg";

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
in {
  wayland.windowManager.hyprland.settings = {
    # Apps
    colorPicker = {
      _var = "${uwsmApp} ${pkgs.hyprpicker}/bin/hyprpicker -a";
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
      (bind (modKey "SHIFT + N") (execCmd "${noctalia} panel-toggle control-center"))
      (bind (modKey "Escape") (execCmd "${noctalia} panel-toggle session"))

      (bind (modKey "Z") (execLocal "colorPicker"))
      (bind (modKey "SHIFT + W") (execCmd "${noctalia} panel-toggle wallpaper"))
      (bind (modKey "SHIFT + R") (execCmd "${noctalia} config-reload"))
      (bind (modKey "Comma") (execCmd "${noctalia} settings-toggle"))

      # Screenshots
      (bind (modKey "SHIFT + S") (execCmd "${noctalia} screenshot-region"))
      (bind "Print" (execCmd "${noctalia} screenshot-fullscreen"))

      # Launcher / emoji / clipboard
      (bind (modKey "Space") (execCmd "${noctalia} panel-toggle launcher"))
      (bind (modKey "U") (execCmd "${noctalia} panel-toggle launcher /emo"))
      (bind (modKey "Y") (execCmd "${noctalia} panel-toggle clipboard"))

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
      (bindWith "XF86AudioLowerVolume" (execCmd "${noctalia} volume-down") {
        locked = true;
        repeating = true;
      })
      (bindWith "XF86AudioRaiseVolume" (execCmd "${noctalia} volume-up") {
        locked = true;
        repeating = true;
      })
      (bindWith "XF86AudioMute" (execCmd "${noctalia} volume-mute") {
        locked = true;
        repeating = true;
      })
      (bindWith "XF86AudioMicMute" (execCmd "${noctalia} mic-mute") {
        locked = true;
        repeating = true;
      })
      (bindWith "XF86MonBrightnessUp" (execCmd "${noctalia} brightness-up") {
        locked = true;
        repeating = true;
      })
      (bindWith "XF86MonBrightnessDown" (execCmd "${noctalia} brightness-down") {
        locked = true;
        repeating = true;
      })

      # Requires an active MPRIS player
      (bindWith "XF86AudioNext" (execCmd "${noctalia} media next") {locked = true;})
      (bindWith "XF86AudioPause" (execCmd "${noctalia} media toggle") {locked = true;})
      (bindWith "XF86AudioPlay" (execCmd "${noctalia} media toggle") {locked = true;})
      (bindWith "XF86AudioPrev" (execCmd "${noctalia} media previous") {locked = true;})
      ]
      ++ builtins.concatLists (map workspaceBind [1 2 3 4 5 6 7 9 10])
      ++ keycodeWorkspaceBinds;
  };
}
