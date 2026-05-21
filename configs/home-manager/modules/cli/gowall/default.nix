{pkgs, ...}: {
  homePackages = with pkgs; [
    gowall
    realesrgan-ncnn-vulkan
    vulkan-tools
  ];

  home.file.".config/gowall/config.yml".text = ''
    themes:
      - name: "black to white"
        colors:
          - "#000000"
          - "#0f0f0f"
          - "#1e1e1e"
          - "#2d2d2d"
          - "#3c3c3c"
          - "#4b4b4b"
          - "#5a5a5a"
          - "#696969"
          - "#787878"
          - "#878787"
          - "#969696"
          - "#a5a5a5"
          - "#b4b4b4"
          - "#c3c3c3"
          - "#d2d2d2"
          - "#e1e1e1"
          - "#f0f0f0"
          - "#ffffff"
      - name: "placeholder2"
        colors:
          - "#F73253"
          - "#FA39DF"
          - "#005382"
          - "#123456"
  '';
}
