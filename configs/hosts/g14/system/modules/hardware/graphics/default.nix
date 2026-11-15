{
  flake.modules.nixos.g14-graphics = {
    # Graphic Settings
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    hardware.amdgpu.overdrive = {
      enable = true;
      ppfeaturemask = "0xffffffff";
    };
  };
}
