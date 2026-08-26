{pkgs, ...}: {
  home.packages = with pkgs; [distrobox];
  programs.distrobox = {
    enable = true;
    settings = {
      container_manager = "docker";
    };
  };
}
