{
  config,
  lib,
  ...
}: let
  mkMangoColor = rgb: alpha: "0x${rgb}${alpha}";
in {
  options.stylix.targets.mango.enable = config.lib.stylix.mkEnableTarget "Mango" true;

  config = lib.mkIf (config.stylix.enable && config.stylix.targets.mango.enable) (
    let
      colors = config.lib.stylix.colors;
      cursor = config.stylix.cursor;
    in {
      wayland.windowManager.mango.settings =
        {
          root_color = lib.mkDefault (mkMangoColor colors.base00 "ff");
          border_color = lib.mkDefault (mkMangoColor colors.base03 "ff");
          focus_color = lib.mkDefault (mkMangoColor colors.base0D "ff");
          urgent_color = lib.mkDefault (mkMangoColor colors.base08 "ff");
          maximized_screen_color = lib.mkDefault (mkMangoColor colors.base0B "ff");
          scratchpad_color = lib.mkDefault (mkMangoColor colors.base0D "ff");
          global_color = lib.mkDefault (mkMangoColor colors.base0E "ff");
          overlay_color = lib.mkDefault (mkMangoColor colors.base0C "ff");
          split_color = lib.mkDefault (mkMangoColor colors.base09 "ff");
          drop_color = lib.mkDefault (mkMangoColor colors.base0B "55");
          shadows_color = lib.mkDefault (mkMangoColor colors.base00 "99");
        }
        // lib.optionalAttrs (cursor != null) {
          cursor_theme = lib.mkDefault cursor.name;
          cursor_size = lib.mkDefault cursor.size;
        };
    }
  );
}
