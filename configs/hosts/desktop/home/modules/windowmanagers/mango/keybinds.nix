{pkgs, ...}: {
  wayland.windowManager.mango.settings.bind = [
    "CTRL,backslash,spawn,${pkgs.handy}/bin/handy --toggle-transcription"
  ];
}
