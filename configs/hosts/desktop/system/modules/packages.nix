{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    mesa-demos
    nvfancontrol
    nvidia-system-monitor-qt
    nvtopPackages.nvidia
    vulkan-tools
  ];
}
