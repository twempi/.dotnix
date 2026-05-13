{
  config,
  lib,
  pkgs,
  quickshellPackage,
  helpers,
}:
{
  qs-quick-actions = {
    Unit = {
      Description = "Resident Quickshell quick action overlays";
    };

    Service = {
      ExecStart = "${lib.getExe quickshellPackage} --config quick-actions";
      Restart = "on-failure";
      RestartSec = 1;
      Environment = [
        "PATH=${lib.makeBinPath [
          helpers.qsPowerAction
          helpers.qsPowerInfo
          helpers.qsFocusedScreenWatch
          helpers.qsPanelAction
          helpers.qsPanelInfo
          helpers.qsManager
          helpers.qsWallpaperApply
          helpers.qsWallpaperList
          pkgs.iproute2
          pkgs.networkmanager
          pkgs.playerctl
          pkgs.swaynotificationcenter
          pkgs.systemd
          pkgs.wireplumber
          pkgs.wlr-randr
          pkgs.coreutils
        ]}:${config.home.profileDirectory}/bin:/run/current-system/sw/bin"
      ];
    };

    Install.WantedBy = [config.wayland.systemd.target];
  };

  qs-wallpaper-cache = {
    Unit = {
      Description = "Warm Quickshell wallpaper thumbnail cache";
    };

    Service = {
      Type = "oneshot";
      ExecStart = "${lib.getExe helpers.qsWallpaperCache} warm";
    };

    Install.WantedBy = [config.wayland.systemd.target];
  };
}
