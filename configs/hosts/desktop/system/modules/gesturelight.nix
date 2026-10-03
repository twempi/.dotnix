{inputs, ...}: {
  imports = [
    inputs.gesturelight.nixosModules.default
  ];
  gesturelight = {
    enable = true;
    url = "192.168.68.72";
  };
}
