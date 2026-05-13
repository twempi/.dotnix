{
  config,
  lib,
  ...
}: {
  # Graphic Settings
  hardware = {
    nvidia = {
      modesetting.enable = true;
      nvidiaPersistenced = true;
      powerManagement = {
        enable = false;
        finegrained = false;
      };
      nvidiaSettings = true;
      open = true;
      package = config.boot.kernelPackages.nvidiaPackages.latest;
    };

    graphics = {
      enable = true;
      enable32Bit = true;
    };
  };

  services.xserver = {
    enable = true;
    deviceSection = lib.mkAfter ''
      Option "Coolbits" "12"
    '';
    videoDrivers = ["nvidia"];
  };

  services.lact.enable = true;

  systemd.user.services.nvidia-powermizer-max = {
    description = "Prefer maximum NVIDIA performance mode";
    after = ["graphical-session.target"];
    wantedBy = ["graphical-session.target"];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${config.hardware.nvidia.package.settings}/bin/nvidia-settings -a [gpu:0]/GPUPowerMizerMode=1";
    };
  };

  environment.sessionVariables = {
    LIBVA_DRIVER_NAME = "nvidia";
    # GBM_BACKEND = "nvidia-drm";
    # __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    __GL_GSYNC_ALLOWED = "1";
    __GL_VRR_ALLOWED = "1";
    __VK_LAYER_NV_optimus = "NVIDIA_only";
    NVD_BACKEND = "direct";
  };
}
