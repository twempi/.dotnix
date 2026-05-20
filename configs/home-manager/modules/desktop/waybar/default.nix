{config, ...}: {
  imports = [
    ./configs/sway-jsonc.nix
    ./configs/mango-jsonc.nix
  ];

  programs.waybar.enable = true;

  xdg.configFile."waybar/hyprland.jsonc".source = ./hyprland.jsonc;
  xdg.configFile."waybar/hyprland.css".source = ./hyprland.css;
  xdg.configFile."waybar/sway.css".source = ./sway.css;
  xdg.configFile."waybar/mango.css".source = ./mango.css;

  xdg.configFile."waybar/scripts" = {
    source = ./scripts;
    recursive = true;
  };

  xdg.configFile."waybar/colors.css".text = ''
    @define-color background                  #${config.lib.stylix.colors.base00};
    @define-color border                      #${config.lib.stylix.colors.base03};
    @define-color text                        #${config.lib.stylix.colors.base05};

    /* workspaces */
    @define-color ws-focused                  #${config.lib.stylix.colors.base0A};
    @define-color ws-active-text              #${config.lib.stylix.colors.base0B};
    @define-color ws-persistent-text          #${config.lib.stylix.colors.base07};
    @define-color ws-urgent                   #${config.lib.stylix.colors.base08};

    /* semantic colors */
    @define-color warning                     #${config.lib.stylix.colors.base09};
    @define-color critical                    #${config.lib.stylix.colors.base08};
    @define-color muted                       #${config.lib.stylix.colors.base03};

    /* module borders / accents */
    @define-color window-border               #${config.lib.stylix.colors.base0E};
    @define-color tray-border                 #${config.lib.stylix.colors.base02};
    @define-color tray-bg                     #${config.lib.stylix.colors.base01};
    @define-color disk-border                 #${config.lib.stylix.colors.base08};
    @define-color cpu-border                  #${config.lib.stylix.colors.base09};
    @define-color temp-border                 #${config.lib.stylix.colors.base0A};
    @define-color backlight-border            #${config.lib.stylix.colors.base0A};
    @define-color memory-border               #${config.lib.stylix.colors.base0C};
    @define-color audio-border                #${config.lib.stylix.colors.base0D};
    @define-color battery-border              #${config.lib.stylix.colors.base0B};
    @define-color clock-border                #${config.lib.stylix.colors.base0A};
    @define-color network-border              #${config.lib.stylix.colors.base0E};

    /* mode indicator */
    @define-color mode-bg                     #${config.lib.stylix.colors.base0D};
    @define-color mode-border                 #${config.lib.stylix.colors.base0C};
    @define-color mode-text                   #${config.lib.stylix.colors.base00};
  '';
}
