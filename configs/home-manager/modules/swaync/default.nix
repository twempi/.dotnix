{config, ...}: {
  imports = [
    ./config.nix
  ];

  services.swaync = {
    enable = true;
    style = "${./style.css}";
  };

  home.file.".config/swaync/colors.css".text = ''
    @define-color bg-primary   #${config.lib.stylix.colors.base00};
    @define-color bg-secondary #${config.lib.stylix.colors.base01};
    @define-color bg-tertiary  #${config.lib.stylix.colors.base02};
    @define-color bg-selected  #${config.lib.stylix.colors.base03};

    @define-color fg-primary   #${config.lib.stylix.colors.base05};
    @define-color fg-secondary #${config.lib.stylix.colors.base04};
    @define-color fg-tertiary  #${config.lib.stylix.colors.base06};
    @define-color fg-disabled  #${config.lib.stylix.colors.base03};

    @define-color accent-green  #${config.lib.stylix.colors.base0B};
    @define-color accent-orange #${config.lib.stylix.colors.base09};
    @define-color accent-red    #${config.lib.stylix.colors.base08};
    @define-color accent-blue   #${config.lib.stylix.colors.base0D};
    @define-color accent-purple #${config.lib.stylix.colors.base0E};

    @define-color border-primary #${config.lib.stylix.colors.base03};
    @define-color border-focus   #${config.lib.stylix.colors.base0B};

    @define-color mpris-album-art-overlay rgba(0, 0, 0, 0.55);
    @define-color mpris-button-hover       rgba(0, 0, 0, 0.5);
  '';
}
