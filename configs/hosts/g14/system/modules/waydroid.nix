{
  pkgs,
  inputs,
  ...
}: {
  nixpkgs.overlays = [
    inputs.nur.overlays.default
  ];
  environment.systemPackages = [
    pkgs.nur.repos.ataraxiasjel.waydroid-script
  ];

  virtualisation.waydroid = {
    enable = true;
    package = pkgs.waydroid-nftables;
  };
}
