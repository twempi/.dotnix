{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    librepods
  ];

  programs.librepods.enable = true;
}
