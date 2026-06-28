{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    nvfancontrol
  ];
}
