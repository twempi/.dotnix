{
  flake.modules.homeManager.hyprland = {
    config,
    lib,
    pkgs,
    ...
  }: let
    lua = lib.generators.mkLuaInline;
    toLua = lib.generators.toLua {};
    uwsmApp = "uwsm app --";
    wpctl = "${pkgs.wireplumber}/bin/wpctl";
    brightnessctl = "${pkgs.brightnessctl}/bin/brightnessctl";
    playerctl = "${pkgs.playerctl}/bin/playerctl";

    # Sway's screenshots: Screenshot-<date>_<time>[-region].png; grimshot's area and screen don't need sway
    # wayfreeze shows a frozen copy of the screen first, so menus that close when slurp grabs input stay in the shot.
    # After exec, $$ is wayfreeze's PID; killing it unfreezes once grimshot finishes or is cancelled.
    screenshot = pkgs.writeShellScript "hyprland-screenshot" ''
      file="${config.home.homeDirectory}/Pictures/Screenshots/Screenshot-$(date +%Y-%m-%d_%H:%M:%S)$2.png"
      exec ${pkgs.wayfreeze}/bin/wayfreeze --hide-cursor --after-freeze-cmd \
        "${pkgs.sway-contrib.grimshot}/bin/grimshot --notify savecopy '$1' '$file'; kill $$"
    '';

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
    forceKillActive = "hyprctl activewindow -j | ${pkgs.jq}/bin/jq -r '.pid // empty' | ${pkgs.findutils}/bin/xargs -r ${pkgs.procps}/bin/kill -KILL";
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
          (bind (modKey "SHIFT + N") (execCmd "amane-notifications"))
          (bind (modKey "Escape") (execCmd "amane-power"))

          (bind (modKey "Z") (execLocal "colorPicker"))
          (bind (modKey "SHIFT + W") (execCmd "amane-wallpaper"))
          (bind (modKey "SHIFT + T") (execCmd "theme-switch --pick"))
          (bind (modKey "SHIFT + R") (execCmd "hyprctl reload"))

          # Screenshots
          (bind (modKey "SHIFT + S") (execCmd "${screenshot} area -region"))
          (bind "Print" (execCmd "${screenshot} screen"))

          # Launcher / emoji / clipboard
          (bind (modKey "Space") (execCmd "amane-launcher"))
          (bind (modKey "U") (execCmd "amane-emoji"))
          (bind (modKey "Y") (execCmd "amane-clipboard"))

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
          (bindWith "XF86AudioLowerVolume" (execCmd "${wpctl} set-volume @DEFAULT_AUDIO_SINK@ 5%-") {
            locked = true;
            repeating = true;
          })
          (bindWith "XF86AudioRaiseVolume" (execCmd "${wpctl} set-volume @DEFAULT_AUDIO_SINK@ 5%+") {
            locked = true;
            repeating = true;
          })
          (bindWith "XF86AudioMute" (execCmd "${wpctl} set-mute @DEFAULT_AUDIO_SINK@ toggle") {
            locked = true;
            repeating = true;
          })
          (bindWith "XF86AudioMicMute" (execCmd "${wpctl} set-mute @DEFAULT_AUDIO_SOURCE@ toggle") {
            locked = true;
            repeating = true;
          })
          (bindWith "XF86MonBrightnessUp" (execCmd "${brightnessctl} set 5%+") {
            locked = true;
            repeating = true;
          })
          (bindWith "XF86MonBrightnessDown" (execCmd "${brightnessctl} set 5%-") {
            locked = true;
            repeating = true;
          })

          # Requires an active MPRIS player
          (bindWith "XF86AudioNext" (execCmd "${playerctl} next") {locked = true;})
          (bindWith "XF86AudioPause" (execCmd "${playerctl} play-pause") {locked = true;})
          (bindWith "XF86AudioPlay" (execCmd "${playerctl} play-pause") {locked = true;})
          (bindWith "XF86AudioPrev" (execCmd "${playerctl} previous") {locked = true;})
        ]
        ++ builtins.concatLists (map workspaceBind [1 2 3 4 5 6 7 9 10])
        ++ keycodeWorkspaceBinds;
    };
  };
}
