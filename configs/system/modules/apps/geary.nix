{pkgs, ...}: {
  environment.systemPackages = with pkgs; [geary];

  programs.geary.enable = true;
}
