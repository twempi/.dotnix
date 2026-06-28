{pkgs, ...}: {
  home.packages = with pkgs; [
    mesa-demos
    nvidia-system-monitor-qt
    nvtopPackages.nvidia
    vulkan-tools
  ];
}
