{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    fancontrol-gui
    mesa-demos
    nvfancontrol
    nvidia-system-monitor-qt
    nvtopPackages.nvidia
    vulkan-tools
    y-cruncher
  ];
}
