{pkgs, ...}: {
  home.packages = with pkgs; [blanket];
  services.blanket.enable = true;
}
