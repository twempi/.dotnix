{pkgs, ...}: {
  home.packages = with pkgs; [
    paprefs
    pasystray
    playerctl
    reaper
  ];
}
