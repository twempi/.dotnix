{
  pkgs,
  config,
  ...
}: {
  stylix.targets.rofi.enable = true;
  home.file.".config/rofi/config.rasi".source = ./config.rasi;
  # home.file.".config/rofi/theme.rasi".source = ./theme.rasi;

  home.file.".config/rofi/scripts/wallpaper.sh" = {
    source = ./wallpaper/wallpaper.sh; # keep your repo path here
    executable = true;
  };
  home.file.".config/rofi/themes/wallpaper.rasi".source = ./wallpaper/wallpaper.rasi;

  home.file.".config/rofi/scripts/powermenu.sh" = {
    source = ./powermenu/powermenu.sh; # <-- your repo path
    executable = true;
  };
  home.file.".config/rofi/themes/powermenu.rasi".source = ./powermenu/powermenu.rasi;

  home.file.".config/rofi/theme.rasi".text = ''
    * {
      font: "JetBrainsMono Nerd Font 11";

      /* Base colors from Stylix/base16 */
      background:        #${config.stylix.base16Scheme.base00};
      background-alt:    #${config.stylix.base16Scheme.base01};
      foreground:        #${config.stylix.base16Scheme.base05};
      foreground-alt:    #${config.stylix.base16Scheme.base06};
      border:            #${config.stylix.base16Scheme.base03};
      active:            #${config.stylix.base16Scheme.base0A};
      urgent:            #${config.stylix.base16Scheme.base08};

      /* Convenience vars matching adi1090x expectations */
      selected:          @active;

      border-colour:               @selected;
      handle-colour:               @selected;
      background-colour:           @background;
      foreground-colour:           @foreground;
      alternate-background:        @background-alt;

      normal-background:           @background;
      normal-foreground:           @foreground;

      urgent-background:           @urgent;
      urgent-foreground:           @background;

      active-background:           @active;
      active-foreground:           @background;

      selected-normal-background:  @selected;
      selected-normal-foreground:  @background;

      selected-urgent-background:  @active;
      selected-urgent-foreground:  @background;

      selected-active-background:  @urgent;
      selected-active-foreground:  @background;

      alternate-normal-background: @background;
      alternate-normal-foreground: @foreground;

      alternate-urgent-background: @urgent;
      alternate-urgent-foreground: @background;

      alternate-active-background: @active;
      alternate-active-foreground: @background;
    }
  '';

  home.packages = [
    (pkgs.writeShellApplication {
      name = "rofi-wallpaper";
      # Add whatever your script uses:
      runtimeInputs = with pkgs; [
        rofi # or rofi-wayland on Wayland
        awww
        libnotify # for notify-send
        findutils
        coreutils
        bash
      ];
      text = ''
        #!/usr/bin/env bash
        exec "${config.xdg.configHome}/rofi/scripts/wallpaper.sh"
      '';
    })

    (pkgs.writeShellApplication {
      name = "rofi-power";
      runtimeInputs = with pkgs; [
        rofi # or rofi on X11
        coreutils
        bash
        # optional: hyprlock swaylock i3lock libnotify (if you use them)
      ];
      text = ''
        #!/usr/bin/env bash
        exec "${config.xdg.configHome}/rofi/scripts/powermenu.sh"
      '';
    })
  ];
}
