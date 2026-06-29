{pkgs, ...}: {
  home = {
    packages = with pkgs; [
      gowall
      realesrgan-ncnn-vulkan
      vulkan-tools
    ];

    file.".config/gowall/config.yml".text = ''
      themes:
        - name: "black to white"
          colors:
            - "#000000"
            - "#050505"
            - "#090909"
            - "#0e0e0e"
            - "#111111"
            - "#141414"
            - "#171717"
            - "#1a1a1a"
            - "#1c1c1c"
            - "#1f1f1f"
            - "#212121"
            - "#242424"
            - "#494949"
            - "#6d6d6d"
            - "#929292"
            - "#b6b6b6"
            - "#dbdbdb"
            - "#ffffff"
        - name: "white to black"
          colors:
            - "#F73253"
            - "#FA39DF"
            - "#005382"
            - "#123456"
    '';
  };
}
