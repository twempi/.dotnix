{inputs, ...}: {
  flake.modules.homeManager.g14-clamshell = {pkgs, ...}: let
    system = pkgs.stdenv.hostPlatform.system;
    hyprctl = "${inputs.hyprland.packages.${system}.hyprland}/bin/hyprctl";
    swaymsg = "${pkgs.sway}/bin/swaymsg";
    wlrRandr = "${pkgs.wlr-randr}/bin/wlr-randr";
    g14RefreshRate = import ../refresh-rate/_package.nix {inherit inputs pkgs system;};

    g14Clamshell = pkgs.writeShellApplication {
      name = "g14-clamshell";

      text =
        ''
          hyprctl_cmd="${hyprctl}"
          swaymsg_cmd="${swaymsg}"
          wlr_randr_cmd="${wlrRandr}"
          refresh_rate_cmd="${g14RefreshRate}/bin/g14-refresh-rate"
        ''
        + builtins.readFile ./clamshell.sh;
    };
  in {
    home.packages = [
      g14Clamshell
    ];

    wayland.windowManager.hyprland.extraLuaFiles."g14-clamshell".content = ''
      hl.on("hyprland.start", function()
        hl.exec_cmd("${g14Clamshell}/bin/g14-clamshell auto")
      end)

      hl.bind("switch:on:Lid Switch", hl.dsp.exec_cmd("${g14Clamshell}/bin/g14-clamshell close"), { locked = true })
      hl.bind("switch:off:Lid Switch", hl.dsp.exec_cmd("${g14Clamshell}/bin/g14-clamshell open"), { locked = true })
    '';

    wayland.windowManager.sway.config = {
      startup = [
        {
          command = "${g14Clamshell}/bin/g14-clamshell auto";
          always = true;
        }
      ];

      bindswitches = {
        "lid:on" = {
          locked = true;
          reload = true;
          action = "exec ${g14Clamshell}/bin/g14-clamshell close";
        };

        "lid:off" = {
          locked = true;
          reload = true;
          action = "exec ${g14Clamshell}/bin/g14-clamshell open";
        };
      };
    };
  };
}
