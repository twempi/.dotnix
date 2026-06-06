{
  inputs,
  system,
  ...
}: let
  mangoPackage = inputs.mangowm.packages.${system}.mango;
in {
  imports = [
    inputs.mangowm.hmModules.mango
    ./stylix.nix
    ./general.nix
    ./env.nix
    ./windowrules.nix
    ./keybinds.nix
    ./screenshot.nix
  ];

  stylix.targets.mango.enable = true;

  wayland.windowManager.mango = {
    enable = true;
    package = mangoPackage;

    autostart_sh = ''
      awww-daemon &
      openrgb --profile ~/.config/OpenRGB/black.orp &

      waybar -c ~/.config/waybar/mango.jsonc -s ~/.config/waybar/mango.css &

      wpctl set-volume @DEFAULT_AUDIO_SINK@ 1 &

      cliphist wipe &
      wl-paste --type text --watch cliphist store &
    '';
  };

  home.sessionVariables = {
    NIXOS_OZONE_WL = 1;
    MOZ_ENABLE_WAYLAND = 1;
    XDG_SESSION_TYPE = "wayland";
    GDK_BACKEND = "wayland,x11";
    QT_QPA_PLATFORM = "wayland;xcb";
    WLR_DRM_NO_ATOMIC = "1";
  };
}
