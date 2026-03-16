{pkgs, ...}: {
  stylix = {
    enable = true;
    autoEnable = false;

    # # A bit changed gruvbox dark hard
    # base16Scheme = {
    # 	base00 = "1d2021";
    # 	base01 = "282828";
    # 	base02 = "3c3836";
    # 	base03 = "504945";
    # 	base04 = "7c6f64";
    # 	base05 = "d5c4a1";
    # 	base06 = "ebdbb2";
    # 	base07 = "fbf1c7";
    # 	base08 = "fb4934";
    # 	base09 = "fe8019";
    # 	base0A = "fabd2f";
    # 	base0B = "b8bb26";
    # 	base0C = "8ec07c";
    # 	base0D = "83a598";
    # 	base0E = "d3869b";
    # 	base0F = "d65d0e";
    # };

    # # Rose pine
    # base16Scheme = {
    # 	base00 = "191724";
    # 	base01 = "1f1d2e";
    # 	base02 = "26233a";
    # 	base03 = "6e6a86";
    # 	base04 = "908caa";
    # 	base05 = "e0def4";
    # 	base06 = "e0def4";
    # 	base07 = "524f67";
    # 	base08 = "eb6f92";
    # 	base09 = "f6c177";
    # 	base0A = "ebbcba";
    # 	base0B = "31748f";
    # 	base0C = "9ccfd8";
    # 	base0D = "c4a7e7";
    # 	base0E = "f6c177";
    # 	base0F = "524f67";
    # };

    # Catpuccin-mocha
    base16Scheme = {
      base00 = "1e1e2e"; # base
      base01 = "181825"; # mantle
      base02 = "313244"; # surface0
      base03 = "45475a"; # surface1
      base04 = "585b70"; # surface2
      base05 = "cdd6f4"; # text
      base06 = "f5e0dc"; # rosewater
      base07 = "b4befe"; # lavender
      base08 = "f38ba8"; # red
      base09 = "fab387"; # peach
      base0A = "f9e2af"; # yellow
      base0B = "a6e3a1"; # green
      base0C = "94e2d5"; # teal
      base0D = "89b4fa"; # blue
      base0E = "cba6f7"; # mauve
      base0F = "f2cdcd"; # flamingo
    };

    # # Stella
    # base16Scheme = {
    #   base00 = "2B213C";
    #   base01 = "362B48";
    #   base02 = "4D4160";
    #   base03 = "655978";
    #   base04 = "7F7192";
    #   base05 = "998BAD";
    #   base06 = "B4A5C8";
    #   base07 = "EBDCFF";
    #   base08 = "C79987";
    #   base09 = "8865C6";
    #   base0A = "C7C691";
    #   base0B = "ACC79B";
    #   base0C = "9BC7BF";
    #   base0D = "A5AAD4";
    #   base0E = "C594FF";
    #   base0F = "C7AB87";
    # };

    # # Material Darker
    # base16Scheme = {
    #   base00 = "212121";
    #   base01 = "303030";
    #   base02 = "353535";
    #   base03 = "4A4A4A";
    #   base04 = "B2CCD6";
    #   base05 = "EEFFFF";
    #   base06 = "EEFFFF";
    #   base07 = "FFFFFF";
    #   base08 = "F07178";
    #   base09 = "F78C6C";
    #   base0A = "FFCB6B";
    #   base0B = "C3E88D";
    #   base0C = "89DDFF";
    #   base0D = "82AAFF";
    #   base0E = "C792EA";
    #   base0F = "FF5370";
    # };

    # # Greyscale
    # base16Scheme = {
    #   base00 = "101010";
    #   base01 = "252525";
    #   base02 = "464646";
    #   base03 = "525252";
    #   base04 = "ababab";
    #   base05 = "b9b9b9";
    #   base06 = "e3e3e3";
    #   base07 = "f7f7f7";
    #   base08 = "7c7c7c";
    #   base09 = "999999";
    #   base0A = "a0a0a0";
    #   base0B = "8e8e8e";
    #   base0C = "868686";
    #   base0D = "686868";
    #   base0E = "747474";
    #   base0F = "5e5e5e";
    # };

    # base16Scheme = {
    #   base00 = "282936"; #background
    #   base01 = "3a3c4e";
    #   base02 = "4d4f68";
    #   base03 = "626483";
    #   base04 = "62d6e8";
    #   base05 = "e9e9f4"; #foreground
    #   base06 = "f1f2f8";
    #   base07 = "f7f7fb";
    #   base08 = "ea51b2";
    #   base09 = "b45bcf";
    #   base0A = "00f769";
    #   base0B = "ebff87";
    #   base0C = "a1efe4";
    #   base0D = "62d6e8";
    #   base0E = "b45bcf";
    #   base0F = "00f769";
    # };

    polarity = "dark";

    cursor = {
      # package = pkgs.volantes-cursors;
      package = pkgs.quintom-cursor-theme;
      name = "Quintom_Ink";
      size = 24;
    };

    fonts = {
      monospace = {
        package = pkgs.fira-code;
        name = "Fira Code";
      };
      sansSerif = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Sans";
      };
      serif = {
        package = pkgs.dejavu_fonts;
        name = "DejaVu Serif";
      };
      sizes = {
        terminal = 11;
        applications = 11;
        desktop = 11;
        popups = 11;
      };
    };
  };
}
