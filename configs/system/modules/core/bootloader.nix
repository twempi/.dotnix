{
  pkgs,
  inputs,
  ...
}: let
  mac-style-src = pkgs.fetchFromGitHub {
    owner = "twempi";
    repo = "plymouth-theme";
    rev = "c69035732627c21e5e8cc3874a38ace6b5794dbf";
    sha256 = "sha256-wIyqW1w2QK4SNKraEySN2eCc1sy5Y5jYrdOoKDLlQd4=";
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
