{pkgs, ...}: {
  wayland.windowManager.sway.config.keybindings = {
    "Ctrl+backslash" = "exec ${pkgs.handy}/bin/handy --toggle-transcription";
  };
}
