{inputs, ...}: {
  imports = [
    inputs.twempi.nixosModules.gesturelight
  ];
  gesturelight = {
    enable =  false;
    url = "192.168.68.60";
  };
}
