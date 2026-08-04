{
  inputs,
  pkgs,
  system,
  ...
}: {
  environment.systemPackages = [
    # Keep the standalone CLI outside the profile it manages.
    inputs.home-manager.packages.${system}.default
    pkgs.nvfancontrol
  ];
}
