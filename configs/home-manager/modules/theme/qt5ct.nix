{
  lib,
  pkgs,
  ...
}: {
  stylix.targets.qt = {
    enable = true;
    platform = "qtct";
  };

  home.activation.removeStaleStylixKvantumTheme = lib.hm.dag.entryBefore ["linkGeneration"] ''
    target="$HOME/.config/Kvantum/Base16Kvantum"

    if [ -L "$target" ]; then
      run ${pkgs.coreutils}/bin/rm -f "$target"
    elif [ -d "$target" ]; then
      unmanaged="$(${pkgs.findutils}/bin/find "$target" -mindepth 1 -maxdepth 1 ! -type l -print -quit)"

      if [ -z "$unmanaged" ]; then
        run ${pkgs.coreutils}/bin/rm -rf "$target"
      else
        stamp="$(${pkgs.coreutils}/bin/date +%Y%m%d%H%M%S)"
        run ${pkgs.coreutils}/bin/mv -T "$target" "$target.hm-backup-$stamp"
      fi
    fi
  '';
}
