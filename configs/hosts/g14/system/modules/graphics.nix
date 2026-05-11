{config, ...}: {
  # Graphic Settings
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.amdgpu.overdrive = {
    enable = true;
    ppfeaturemask = "0xffffffff";
  };

  services.switcherooControl.enable = true;
}
