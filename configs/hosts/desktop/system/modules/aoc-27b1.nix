{
  hardware.display.edid.modelines."AOC_27B1_65" =
    "188.00 1920 2048 2248 2576 1080 1083 1088 1124 -hsync +vsync";

  hardware.display.outputs."HDMI-A-1".edid = "AOC_27B1_65.bin";

  # Optional, but often useful for stubborn HDMI/AMD display paths:
  hardware.display.outputs."HDMI-A-1".mode = "e";
}
