{pkgs, ...}: let
  terminal = "${pkgs.kitty}/bin/kitty";
  colorPicker = "${pkgs.hyprpicker}/bin/hyprpicker -a";
  notiCenter = "${pkgs.swaynotificationcenter}/bin/swaync-client -t -sw";

  browser = "helium";
  explorer1 = "${terminal} -e ${pkgs.yazi}/bin/yazi";
  explorer2 = "${pkgs.nautilus}/bin/nautilus";
  notes = "${pkgs.obsidian}/bin/obsidian";
  bluetooth = "${terminal} -e ${pkgs.bluetui}/bin/bluetui";
  editor = "${terminal} -e nvim";

  tagNumbers = builtins.genList (i: i + 1) 9;
  numberKeyFor = tag: toString tag;
  tagBind = tag: let
    key = numberKeyFor tag;
    tagString = toString tag;
  in [
    "SUPER,${key},view,${tagString}"
    "SUPER+SHIFT,${key},tagsilent,${tagString}"
  ];
  keycodeTagBinds = builtins.concatLists (builtins.genList (i: let
      tag = i + 1;
      code = i + 10;
      tagString = toString tag;
      codeString = toString code;
    in [
      "SUPER,code:${codeString},view,${tagString}"
      "SUPER+SHIFT,code:${codeString},tagsilent,${tagString}"
    ])
    9);
in {
  wayland.windowManager.mango.settings = {
    bind =
      [
        "SUPER,Q,killclient"
        "SUPER,V,togglefloating"
        "SUPER,F,togglemaximizescreen"
        "SUPER+SHIFT,F,togglefullscreen"

        "SUPER,Return,spawn,${terminal}"
        "SUPER,B,spawn,${browser}"
        "SUPER,E,spawn,${explorer1}"
        "SUPER+SHIFT,E,spawn,${explorer2}"
        "SUPER,M,spawn,spotify"
        "SUPER,O,spawn,${notes}"
        "SUPER,N,spawn,${editor}"
        "SUPER+SHIFT,B,spawn,${bluetooth}"
        "SUPER+SHIFT,N,spawn,${notiCenter}"
        "SUPER,Escape,spawn,rofi-power"

        "SUPER,Z,spawn,${colorPicker}"
        "SUPER+SHIFT,W,spawn,rofi-wallpaper"
        "SUPER+SHIFT,R,spawn,bash ${./reload.sh}"

        "SUPER+SHIFT,S,spawn,way-screenshot area"
        "NONE,Print,spawn,way-screenshot screen"

        "SUPER,Space,spawn,rofi-launcher"
        "SUPER,U,spawn,rofi-emoji"
        "SUPER,Y,spawn,rofi-clipboard"

        "SUPER,H,focusdir,left"
        "SUPER,L,focusdir,right"
        "SUPER,J,focusdir,down"
        "SUPER,K,focusdir,up"

        "SUPER+CTRL,H,exchange_client,left"
        "SUPER+CTRL,L,exchange_client,right"
        "SUPER+CTRL,J,exchange_client,down"
        "SUPER+CTRL,K,exchange_client,up"

        "SUPER+SHIFT,H,resizewin,-50,0"
        "SUPER+SHIFT,L,resizewin,+50,0"
        "SUPER+SHIFT,J,resizewin,0,-50"
        "SUPER+SHIFT,K,resizewin,0,+50"

        "NONE,XF86AudioLowerVolume,spawn,${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
        "NONE,XF86AudioRaiseVolume,spawn,${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
        "NONE,XF86AudioMute,spawn,${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
        "NONE,XF86AudioMicMute,spawn,${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
        "NONE,XF86MonBrightnessUp,spawn,${pkgs.brightnessctl}/bin/brightnessctl set 5%+"
        "NONE,XF86MonBrightnessDown,spawn,${pkgs.brightnessctl}/bin/brightnessctl set 5%-"

        "NONE,XF86AudioNext,spawn,${pkgs.playerctl}/bin/playerctl next"
        "NONE,XF86AudioPause,spawn,${pkgs.playerctl}/bin/playerctl play-pause"
        "NONE,XF86AudioPlay,spawn,${pkgs.playerctl}/bin/playerctl play-pause"
        "NONE,XF86AudioPrev,spawn,${pkgs.playerctl}/bin/playerctl previous"
      ]
      ++ builtins.concatLists (map tagBind tagNumbers);
    # ++ keycodeTagBinds;

    mousebind = [
      "SUPER,btn_left,moveresize,curmove"
      "SUPER,btn_right,moveresize,curresize"
    ];
  };
}
