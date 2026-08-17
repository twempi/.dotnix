{
  inputs,
  pkgs,
  system,
  ...
}: let
  g14RefreshRate = import ./package.nix {inherit inputs pkgs system;};
  sessionStart = "${g14RefreshRate}/bin/g14-refresh-rate --session-start";
in {
  home.packages = [
    g14RefreshRate
  ];

  wayland.windowManager.hyprland.extraLuaFiles."g14-refresh-rate".content = ''
    hl.on("hyprland.start", function()
      hl.exec_cmd("${sessionStart}")
    end)
  '';

  wayland.windowManager.sway.config.startup = [
    {
      command = sessionStart;
      always = false;
    }
  ];

  wayland.windowManager.mango.autostart_sh = ''
    ${sessionStart}
  '';

  systemd.user.services.g14-refresh-rate = {
    Unit = {
      Description = "Set G14 internal panel refresh rate from AC state";
      PartOf = ["graphical-session.target"];
      After = ["graphical-session.target"];
      ConditionEnvironment = ["WAYLAND_DISPLAY"];
    };

    Service = {
      Type = "simple";
      ExecStart = "${g14RefreshRate}/bin/g14-refresh-rate --watch";
      Restart = "on-failure";
      RestartSec = "5s";
      Slice = "background.slice";
    };
  };
}
