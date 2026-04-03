
{
  pkgs,
  ...
}: {
 wayland.windowManager.sway.config = {
   keybinds = {
      # Multimedia keys
      "XF86AudioLowerVolume" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
      "XF86AudioRaiseVolume" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+";
      "XF86AudioMute" = "exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
      "XF86AudioMicMute" = "exec wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
      "XF86MonBrightnessUp" = "asusctl leds next";
      "XF86MonBrightnessDown" = "asusctl leds prev";
      "XF86Launch4" = "asusctl profile next";
   };
 };
}
