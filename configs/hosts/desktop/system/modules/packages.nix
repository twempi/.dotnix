{
  inputs,
  pkgs,
  system,
  ...
}: {
  environment.systemPackages = [
    inputs.home-manager.packages.${system}.default
    pkgs.nvfancontrol
  ];
}
