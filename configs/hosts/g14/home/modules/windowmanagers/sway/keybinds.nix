{pkgs, ...}: let
  asusProfileNotify = pkgs.writeShellScriptBin "asus-profile-notify" ''
    #!${pkgs.bash}/bin/bash

    ${pkgs.asusctl}/bin/asusctl profile next

    profile="$(
      ${pkgs.asusctl}/bin/asusctl profile get 2>/dev/null \
        | head -n1 \
        | sed 's/^Active profile:[[:space:]]*//'
    )"

    if [ -z "$profile" ]; then
      profile="Profile changed"
    fi

    ${pkgs.libnotify}/bin/notify-send "ASUS profile" "$profile"
  '';
in {
  home.packages = [
    asusProfileNotify
  ];

  wayland.windowManager.sway.config.keybindings = {
    "XF86KbdBrightnessUp" = "exec asusctl leds next";
    "XF86KbdBrightnessDown" = "exec asusctl leds prev";
    "XF86Launch4" = "exec ${pkgs.libnotify}/bin/notify-send 'ASUS profile' 'keybind test'";
  };
}
