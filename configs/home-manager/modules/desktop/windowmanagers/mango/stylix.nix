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
          rootcolor = lib.mkDefault (mkMangoColor colors.base00 "ff");
          bordercolor = lib.mkDefault (mkMangoColor colors.base03 "ff");
          focuscolor = lib.mkDefault (mkMangoColor colors.base0D "ff");
          urgentcolor = lib.mkDefault (mkMangoColor colors.base08 "ff");
          maximizescreencolor = lib.mkDefault (mkMangoColor colors.base0B "ff");
          scratchpadcolor = lib.mkDefault (mkMangoColor colors.base0D "ff");
          globalcolor = lib.mkDefault (mkMangoColor colors.base0E "ff");
          overlaycolor = lib.mkDefault (mkMangoColor colors.base0C "ff");
          splitcolor = lib.mkDefault (mkMangoColor colors.base09 "ff");
          dropcolor = lib.mkDefault (mkMangoColor colors.base0B "55");
          shadowscolor = lib.mkDefault (mkMangoColor colors.base00 "99");
        }
        // lib.optionalAttrs (cursor != null) {
          cursor_theme = lib.mkDefault cursor.name;
          cursor_size = lib.mkDefault cursor.size;
        };
    }
  );
}
