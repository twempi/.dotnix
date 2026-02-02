{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    fancontrol-gui
  ];
}
