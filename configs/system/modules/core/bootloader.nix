{
  pkgs,
  inputs,
  lib,
  ...
}: let
  mac-style-src = pkgs.fetchFromGitHub {
    owner = "twempi";
    repo = "plymouth-theme";
    rev = "b305c7200b90c204ad69c23ea5a4ae16939e6fc8";
    sha256 = "sha256-dlNXlIPxPSDbai8W1itxsTG93l5735uP15pCqFDoQV8=";
  };

  mac-style-load = pkgs.callPackage "${mac-style-src}/package.nix" {};
in {
  imports = [
    inputs.minimal-grub-theme.nixosModules.default
  ];
  stylix.targets.grub.enable = false;

  boot = {
    loader = {
      efi.canTouchEfiVariables = true;

      grub = {
        enable = true;
        devices = ["nodev"];
        efiSupport = true;
        useOSProber = true;

        gfxmodeEfi = "auto";
        gfxpayloadEfi = "keep";

        minimalTheme = {
          enable = true;
          fontSize = 28;
          fontRange = "0x20-0x7e,0xa0-0xff,0x2010-0x2026";
          timeout = 5;
        };
      };

      timeout = 5;
    };

    plymouth = {
      enable = true;
      theme = "mac-style";
      themePackages = [mac-style-load];
    };

    consoleLogLevel = 3;
    initrd.verbose = false;
    kernelParams = [
      "quiet"
      "udev.log_level=3"
      "systemd.show_status=auto"
    ];
  };
}
