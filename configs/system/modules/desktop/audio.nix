{
  pkgs,
  pkgsStable,
  ...
}: {
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    jack.enable = true;
    wireplumber.enable = true;
  };

  hardware = {
    bluetooth = {
      enable = true;
      # package = pkgsStable.bluez;
      powerOnBoot = true;
      settings = {
        General = {
          Experimental = true;
        };
      };
    };
  };
}
