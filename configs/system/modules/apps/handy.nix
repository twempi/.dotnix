{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.handy;
in {
  options.programs.handy = {
    enable = lib.mkEnableOption "Handy offline speech-to-text";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.handy;
      defaultText = lib.literalExpression "pkgs.handy";
      description = "The Handy package to use.";
    };

    autostart = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to start Handy in the graphical user session.";
    };
  };

  config = lib.mkMerge [
    {
      programs.handy = {
        enable = true;
        autostart = false;
      };
    }
    (lib.mkIf cfg.enable {
      environment.systemPackages = [
        cfg.package
        pkgs.wtype
        pkgs.xdotool
      ];

      services.udev.extraRules = ''
        KERNEL=="uinput", GROUP="input", MODE="0660"
      '';

      systemd.user.services.handy = lib.mkIf cfg.autostart {
        description = "Handy speech-to-text";
        partOf = ["graphical-session.target"];
        after = ["graphical-session.target"];
        wantedBy = ["graphical-session.target"];
        environment.WEBKIT_DISABLE_DMABUF_RENDERER = "1";

        serviceConfig = {
          ExecStart = "${lib.getExe cfg.package} --start-hidden";
          Restart = "on-failure";
          RestartSec = "5s";
        };
      };
    })
  ];
}
