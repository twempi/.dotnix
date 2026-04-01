{ config, pkgs, ... }:

let
  # This points to the EDID file you just created next to configuration.nix
  aocEdid = ./aoc-q27g3xmn.bin;
in {
  # Install the EDID blob as kernel firmware under /lib/firmware/edid/
  hardware.firmware = [
    (pkgs.runCommand "aoc-q27g3xmn-edid" {} ''
      mkdir -p $out/lib/firmware/edid
      cp ${aocEdid} $out/lib/firmware/edid/aoc-q27g3xmn.bin
    '')
  ];

  # Tell the kernel to use that EDID for DP-3 (your NVIDIA connector)
  boot.kernelParams = [
    "drm.edid_firmware=DP-3:edid/aoc-q27g3xmn.bin"
  ];

  # Make sure you're using the NVIDIA driver
  services.xserver.videoDrivers = [ "nvidia" ];

  # Optional: if you also use Xorg at all, this helps there too:
  services.xserver.screenSection = ''
    Option "CustomEDID" "DP-3:/lib/firmware/edid/aoc-q27g3xmn.bin"
    Option "UseEDID" "true"
    Option "UseEDIDFreqs" "true"
    Option "UseEDIDDpi" "true"
  '';
}
