{
  hardware.display.edid.enable = true;

  hardware.display.edid.modelines."AOC_27B1_70" =
    "204.25 1920 2056 2256 2592 1080 1083 1088 1127 -hsync +vsync";

  hardware.display.outputs."HDMI-A-1".edid = "AOC_27B1_70.bin";
  hardware.display.outputs."HDMI-A-1".mode = "e";
}
