{pkgs, ...}: {
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    pulse.enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    jack.enable = true;

    wireplumber = {
      enable = true;
      extraConfig = {
        "11-bluetooth-policy" = {
          "wireplumber.settings" = {
            "bluetooth.autoswitch-to-headset-profile" = false;
          };
        };

        "10-bluez" = {
          "monitor.bluez.properties" = {
            "bluez5.enable-sbc-xq" = true;
            "bluez5.enable-msbc" = true;

            # Optional: keep codec choices simple for AirPods
            "bluez5.codecs" = ["aac" "sbc_xq" "sbc"];
          };
        };
      };
    };
  };

  environment.systemPackages = with pkgs; [
    paprefs
    pasystray
    playerctl
    reaper
  ];

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Experimental = true;
      };
    };
  };
}
