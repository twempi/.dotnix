{
  lib,
  pkgs,
  ...
}: let
  toLua = lib.generators.toLua {};
in {
  wayland.windowManager.hyprland.settings.bind = [
    {
      _args = [
        "CTRL + backslash"
        (lib.generators.mkLuaInline "hl.dsp.exec_cmd(${toLua "${pkgs.handy}/bin/handy --toggle-transcription"})")
      ];
    }
  ];
}
