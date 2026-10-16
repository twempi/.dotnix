{
  inputs,
  pkgs,
  ...
}: {
  imports = [
    inputs.niri.nixosModules.niri
  ];

  programs.niri = {
    enable = true;
    # niri-flake's packages are built against its own (older) nixpkgs, so they
    # can't load the system's newer Mesa (GLIBC_2.43 not found) and niri ends up
    # with no outputs. Use nixpkgs' niri so it shares the system glibc/Mesa.
    package = pkgs.niri;
  };

  niri-flake.cache.enable = true;

  xdg.portal.config.niri.default = ["gnome" "gtk"];
}
