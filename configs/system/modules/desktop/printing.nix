{pkgs, ...}: {
  services.printing = {
    enable = true;
    webInterface = true;
    browsed.enable = true;

    # Exposes BlueZ's /lib/cups/backend/bluetooth as a fallback backend.
    drivers = with pkgs; [
      bluez
    ];
  };

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };
}
