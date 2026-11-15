{
  flake.modules.nixos.services = {pkgs, ...}: {
    environment.systemPackages = [
      pkgs.gnome-keyring
    ];

    services = {
      gnome.gnome-keyring.enable = true;
      upower.enable = true;
    };
  };
}
