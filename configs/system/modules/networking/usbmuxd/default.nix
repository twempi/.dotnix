{
  flake.modules.nixos.usbmuxd = {pkgs, ...}: {
    environment.systemPackages = with pkgs; [
      usbmuxd
    ];
    services.usbmuxd.enable = true;
  };
}
