{inputs, ...}: {
  imports = [
    inputs.twempi.nixosModules.gesturelight
  ];
  gesturelight = {
    enable = true;
    url = "192.168.68.60";
  };
}
