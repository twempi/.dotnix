{
  flake.modules.nixos.audio = {lib, ...}: {
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
        powerOnBoot = lib.mkDefault true;
        settings = {
          General = {
            Experimental = true;
          };
        };
      };
    };
  };
}
