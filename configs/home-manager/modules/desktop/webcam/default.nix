{ pkgs, ... }:

{
  home.packages = with pkgs; [
    libv4l        # provides v4l2-ctl
    cameractrls  # GUI, optional
    guvcview     # GUI, optional
  ];

  # systemd.user.services.c270-settings = {
  #   Unit = {
  #     Description = "Apply Logitech C270 webcam settings";
  #     After = [ "graphical-session.target" ];
  #   };
  #
  #   Service = {
  #     Type = "oneshot";
  #     ExecStart = pkgs.writeShellScript "c270-settings" ''
  #       cam=$(readlink -f /dev/v4l/by-id/*C270*video-index0 2>/dev/null | head -n1)
  #       [ -n "$cam" ] || exit 0
  #
  #       ${pkgs.libv4l}/bin/v4l2-ctl -d "$cam" -c brightness=140,contrast=40,saturation=60
  #       ${pkgs.libv4l}/bin/v4l2-ctl -d "$cam" -c power_line_frequency=2
  #       ${pkgs.libv4l}/bin/v4l2-ctl -d "$cam" -c white_balance_temperature_auto=0,white_balance_temperature=4500
  #       ${pkgs.libv4l}/bin/v4l2-ctl -d "$cam" -c exposure_auto=1,exposure_absolute=160
  #     '';
  #   };
  #
  #   Install = {
  #     WantedBy = [ "graphical-session.target" ];
  #   };
  # };
}
